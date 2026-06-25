import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'amap_controller.dart';
import 'models/map_marker.dart';
import 'models/map_track.dart';
import 'models/map_route.dart';

class AmapWidget extends StatefulWidget {
  final AmapController? controller;
  final LatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<MapTrack> tracks;
  final List<MapRoute> routes;
  final List<MapMarker> markers;
  final bool showZoomControls;
  final PositionCallback? onPositionChanged;

  const AmapWidget({
    super.key,
    this.controller,
    this.center = const LatLng(39.9042, 116.4074),
    this.zoom = 14.0,
    this.minZoom = 3.0,
    this.maxZoom = 20.0,
    this.tracks = const [],
    this.routes = const [],
    this.markers = const [],
    this.showZoomControls = true,
    this.onPositionChanged,
  });

  @override
  State<AmapWidget> createState() => _AmapWidgetState();
}

class _AmapWidgetState extends State<AmapWidget>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _animController;
  Animation<LatLng>? _positionAnim;
  Animation<double>? _zoomAnim;
  AmapController? _internalController;

  AmapController get _controller =>
      widget.controller ?? (_internalController ??= AmapController());

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _controller.bindMapController(_mapController);

    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(_onAnimTick);

    if (widget.controller == null) {
      _setupInternalController();
    }
  }

  void _setupInternalController() {
    _internalController = AmapController();
    _internalController!.bindMapController(_mapController);
    _internalController!.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(AmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      _internalController?.removeListener(_onControllerUpdate);
      _internalController?.dispose();
      _internalController = null;

      if (widget.controller != null) {
        widget.controller!.bindMapController(_mapController);
      } else {
        _setupInternalController();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _onAnimTick() {
    if (_positionAnim != null && _zoomAnim != null) {
      _mapController.move(_positionAnim!.value, _zoomAnim!.value);
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    _animController.duration = c.animDuration;
    _positionAnim = LatLngTween(begin: c.animStart, end: c.animEnd).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _zoomAnim =
        Tween<double>(begin: c.animStartZoom, end: c.animEndZoom).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
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
              widget.onPositionChanged?.call(camera, hasGesture);
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
          ],
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

  List<PolylineLayer> _buildTracks() {
    return widget.tracks.map((track) {
      return PolylineLayer(
        polylines: [
          Polyline(
            points: track.points,
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
              points: route.points,
              color: route.highlightColor ?? route.color.withValues(alpha: 0.4),
              strokeWidth: route.highlightWidth,
            ),
          Polyline(
            points: route.points,
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
            point: p,
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
          point: route.points.first,
          width: 30,
          height: 50,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('起点',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Icon(Icons.location_on, color: Colors.green, size: 24),
            ],
          ),
        ),
      );
      allDots.add(
        Marker(
          point: route.points.last,
          width: 30,
          height: 50,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('终点',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
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
        point: m.point,
        width: m.width,
        height: m.height,
        child: m.child,
      );
    }).toList();
  }
}
