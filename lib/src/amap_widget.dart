import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'amap_controller.dart';
import 'amap_fallback_widget.dart';
import 'models/amap_latlng.dart';
import 'models/location_result.dart';
import 'models/map_marker.dart';
import 'models/map_track.dart';
import 'models/map_route.dart';

class AmapWidget extends StatefulWidget {
  final AmapController? controller;
  final AmapLatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<MapTrack> tracks;
  final List<MapRoute> routes;
  final List<MapMarker> markers;
  final bool showZoomControls;
  final bool showMyLocation;
  final LocationResult? currentLocation;
  final PositionCallback? onPositionChanged;

  const AmapWidget({
    super.key,
    this.controller,
    this.center = const AmapLatLng(39.9042, 116.4074),
    this.zoom = 18.0,
    this.minZoom = 3.0,
    this.maxZoom = 20.0,
    this.tracks = const [],
    this.routes = const [],
    this.markers = const [],
    this.showZoomControls = true,
    this.showMyLocation = false,
    this.currentLocation,
    this.onPositionChanged,
  });

  @override
  State<AmapWidget> createState() => _AmapWidgetState();
}

class _AmapWidgetState extends State<AmapWidget> {
  static const _channel = MethodChannel('com.example.amap_flutter_plugin');
  bool _isAmapAvailable = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isAmapAvailable = false;
      _checking = false;
    } else {
      _checkAmapSdkNative();
    }
  }

  Future<void> _checkAmapSdkNative() async {
    try {
      final result = await _channel.invokeMethod('isAmapSdkAvailable');
      if (mounted) {
        setState(() {
          _isAmapAvailable = result == true;
          _checking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAmapAvailable = false;
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const SizedBox.shrink();
    }

    if (!_isAmapAvailable) {
      return AmapFallbackWidget(
        controller: widget.controller,
        center: widget.center,
        zoom: widget.zoom,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        tracks: widget.tracks,
        routes: widget.routes,
        markers: widget.markers,
        showZoomControls: widget.showZoomControls,
        showMyLocation: widget.showMyLocation,
        currentLocation: widget.currentLocation,
        onPositionChanged: widget.onPositionChanged,
      );
    }

    return _NativeAmapWidget(
      controller: widget.controller,
      center: widget.center,
      zoom: widget.zoom,
      minZoom: widget.minZoom,
      maxZoom: widget.maxZoom,
      tracks: widget.tracks,
      routes: widget.routes,
      markers: widget.markers,
      showZoomControls: widget.showZoomControls,
      showMyLocation: widget.showMyLocation,
      currentLocation: widget.currentLocation,
      onCameraIdle: widget.onPositionChanged,
    );
  }
}

typedef PositionCallback = void Function(
    double lat, double lng, double zoom, bool hasGesture);

class _NativeAmapWidget extends StatefulWidget {
  final AmapController? controller;
  final AmapLatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<MapTrack> tracks;
  final List<MapRoute> routes;
  final List<MapMarker> markers;
  final bool showZoomControls;
  final bool showMyLocation;
  final LocationResult? currentLocation;
  final void Function(double lat, double lng, double zoom, bool hasGesture)? onCameraIdle;

  const _NativeAmapWidget({
    this.controller,
    this.center = const AmapLatLng(39.9042, 116.4074),
    this.zoom = 18.0,
    this.minZoom = 3.0,
    this.maxZoom = 20.0,
    this.tracks = const [],
    this.routes = const [],
    this.markers = const [],
    this.showZoomControls = true,
    this.showMyLocation = false,
    this.currentLocation,
    this.onCameraIdle,
  });

  @override
  State<_NativeAmapWidget> createState() => _NativeAmapWidgetState();
}

class _NativeAmapWidgetState extends State<_NativeAmapWidget> {
  AmapController? _internalController;
  MethodChannel? _channel;

  AmapController get _controller =>
      widget.controller ?? (_internalController ??= AmapController());

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = AmapController();
    }
  }

  @override
  void didUpdateWidget(_NativeAmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      _internalController?.removeListener(_onControllerUpdate);
      _internalController?.dispose();
      _internalController = null;

      if (widget.controller != null) {
        widget.controller!.addListener(_onControllerUpdate);
      } else {
        _internalController = AmapController();
        _internalController!.addListener(_onControllerUpdate);
      }
    }
    _updateOverlays();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _internalController?.removeListener(_onControllerUpdate);
    _internalController?.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('com.example.amap_flutter_plugin/map_$id');
    _channel!.setMethodCallHandler(_onMethodCall);
    _controller.bindChannel(_channel!);

    _channel!.invokeMethod('init', {
      'lat': widget.center.latitude,
      'lng': widget.center.longitude,
      'zoom': widget.zoom,
    });

    _controller.addListener(_onControllerUpdate);
    _updateOverlays();
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCameraIdle':
        final lat = call.arguments['lat'] as double;
        final lng = call.arguments['lng'] as double;
        final zoom = call.arguments['zoom'] as double;
        _controller.onCameraIdle(lat, lng, zoom);
        widget.onCameraIdle?.call(lat, lng, zoom, true);
        break;
    }
  }

  void _updateOverlays() {
    if (_channel == null) return;

    _channel!.invokeMethod('addMarkers', widget.markers.map((m) {
      return {
        'lat': m.point.latitude,
        'lng': m.point.longitude,
        'title': '',
      };
    }).toList());

    _channel!.invokeMethod('addPolylines', [
      ...widget.routes.map((r) {
        return {
          'points': r.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          'color': r.color.value,
          'width': r.strokeWidth,
        };
      }),
      ...widget.tracks.map((t) {
        return {
          'points': t.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          'color': t.color.value,
          'width': t.strokeWidth,
        };
      }),
    ]);

    if (widget.tracks.any((t) => t.showDots)) {
      final allDots = <Map<String, double>>[];
      for (final track in widget.tracks) {
        if (!track.showDots) continue;
        for (final p in track.points) {
          allDots.add({'lat': p.latitude, 'lng': p.longitude});
        }
      }
      _channel!.invokeMethod('addTrackDots', {
        'points': allDots,
        'color': widget.tracks.first.dotColor?.value ?? widget.tracks.first.color.value,
        'size': widget.tracks.first.dotSize,
      });
    }

    _channel!.invokeMethod('setMyLocationEnabled', {
      'enabled': widget.showMyLocation && widget.currentLocation != null,
      'lat': widget.currentLocation?.location.latitude,
      'lng': widget.currentLocation?.location.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AndroidView(
          viewType: 'com.example.amap_flutter_plugin/map',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: <String, dynamic>{
            'lat': widget.center.latitude,
            'lng': widget.center.longitude,
            'zoom': widget.zoom,
          },
          creationParamsCodec: const StandardMessageCodec(),
        ),
        if (widget.showZoomControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'amap_zoom_in',
                  onPressed: () =>
                      _controller.zoomIn(widget.minZoom, widget.maxZoom),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'amap_zoom_out',
                  onPressed: () =>
                      _controller.zoomOut(widget.minZoom, widget.maxZoom),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'amap_reset',
                  onPressed: () =>
                      _controller.resetView(widget.center, widget.zoom),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
