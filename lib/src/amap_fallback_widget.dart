import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'amap_controller.dart';
import 'models/amap_latlng.dart';
import 'models/location_result.dart';
import 'models/map_marker.dart';
import 'models/map_track.dart';
import 'models/map_route.dart';

class AmapFallbackWidget extends StatefulWidget {
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
  final void Function(double lat, double lng, double zoom, bool hasGesture)? onPositionChanged;

  const AmapFallbackWidget({
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
  State<AmapFallbackWidget> createState() => _AmapFallbackWidgetState();
}

class _AmapFallbackWidgetState extends State<AmapFallbackWidget> {
  late final MapController _mapController;
  AmapController? _internalController;

  AmapController get _controller =>
      widget.controller ?? (_internalController ??= AmapController());

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.controller == null) {
      _internalController = AmapController();
    }
  }

  @override
  void didUpdateWidget(AmapFallbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _internalController?.dispose();
      _internalController = null;

      if (widget.controller == null) {
        _internalController = AmapController();
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  LatLng _toLatLng(AmapLatLng p) => LatLng(p.latitude, p.longitude);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _toLatLng(widget.center),
            initialZoom: widget.zoom,
            maxZoom: widget.maxZoom,
            minZoom: widget.minZoom,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(-85.0, -180.0),
                const LatLng(85.0, 180.0),
              ),
            ),
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                _controller.updateZoom(camera.zoom);
              }
              widget.onPositionChanged?.call(
                camera.center.latitude,
                camera.center.longitude,
                camera.zoom,
                hasGesture,
              );
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'http://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7',
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: 'com.example.amap_flutter_plugin',
            ),
            ..._buildTracks(),
            ..._buildRoutes(),
            _buildTrackDots(),
            _buildRouteDots(),
            MarkerLayer(markers: _buildMarkers()),
            if (widget.showMyLocation && widget.currentLocation != null)
              MarkerLayer(markers: [_buildMyLocationMarker()]),
          ],
        ),
        if (widget.showZoomControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'fallback_zoom_in',
                  onPressed: () =>
                      _controller.zoomIn(widget.minZoom, widget.maxZoom),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fallback_zoom_out',
                  onPressed: () =>
                      _controller.zoomOut(widget.minZoom, widget.maxZoom),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fallback_reset',
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

  List<PolylineLayer> _buildTracks() {
    return widget.tracks.map((track) {
      return PolylineLayer(
        polylines: [
          Polyline(
            points: track.points.map(_toLatLng).toList(),
            color: track.color,
            strokeWidth: track.strokeWidth,
          ),
        ],
      );
    }).toList();
  }

  List<PolylineLayer> _buildRoutes() {
    return widget.routes.map((route) {
      return PolylineLayer(
        polylines: [
          if (route.showHighlight)
            Polyline(
              points: route.points.map(_toLatLng).toList(),
              color: route.highlightColor ?? route.color.withValues(alpha: 0.4),
              strokeWidth: route.highlightWidth,
            ),
          Polyline(
            points: route.points.map(_toLatLng).toList(),
            color: route.color,
            strokeWidth: route.strokeWidth,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildTrackDots() {
    final allDots = <Marker>[];
    for (final track in widget.tracks) {
      if (!track.showDots) continue;
      allDots.addAll(
        track.points.map(
          (p) => Marker(
            point: _toLatLng(p),
            width: track.dotSize + 14,
            height: track.dotSize + 14,
            child: Icon(
              Icons.circle,
              color: track.dotColor ?? track.color,
              size: track.dotSize,
            ),
          ),
        ),
      );
    }
    if (allDots.isEmpty) return const SizedBox.shrink();
    return MarkerLayer(markers: allDots);
  }

  Widget _buildRouteDots() {
    final allDots = <Marker>[];
    for (final route in widget.routes) {
      if (route.points.length < 2) continue;
      allDots.add(
        Marker(
          point: _toLatLng(route.points.first),
          width: 30,
          height: 50,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '起点',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.location_on, color: Colors.green, size: 24),
            ],
          ),
        ),
      );
      allDots.add(
        Marker(
          point: _toLatLng(route.points.last),
          width: 30,
          height: 50,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '终点',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.location_on, color: Colors.red, size: 24),
            ],
          ),
        ),
      );
    }
    if (allDots.isEmpty) return const SizedBox.shrink();
    return MarkerLayer(markers: allDots);
  }

  List<Marker> _buildMarkers() {
    return widget.markers.map((m) {
      return Marker(
        point: _toLatLng(m.point),
        width: m.width,
        height: m.height,
        child: m.child,
      );
    }).toList();
  }

  Marker _buildMyLocationMarker() {
    return Marker(
      point: _toLatLng(widget.currentLocation!.location),
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
