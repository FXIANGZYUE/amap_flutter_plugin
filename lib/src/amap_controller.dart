import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AmapController extends ChangeNotifier {
  MapController? _mapController;
  double _currentZoom = 14.0;

  Duration _animDuration = const Duration(milliseconds: 500);
  LatLng _animStart = const LatLng(0, 0);
  LatLng _animEnd = const LatLng(0, 0);
  double _animStartZoom = 14.0;
  double _animEndZoom = 14.0;

  void bindMapController(MapController controller) {
    _mapController = controller;
  }

  MapController? get mapController => _mapController;
  Duration get animDuration => _animDuration;
  LatLng get animStart => _animStart;
  LatLng get animEnd => _animEnd;
  double get animStartZoom => _animStartZoom;
  double get animEndZoom => _animEndZoom;
  double get currentZoom => _currentZoom;

  void animateTo(LatLng target, double targetZoom) {
    if (_mapController == null) return;

    final startCenter = _mapController!.camera.center;
    final startZoom = _mapController!.camera.zoom;
    final latDiff = (target.latitude - startCenter.latitude).abs();
    final lngDiff = (target.longitude - startCenter.longitude).abs();
    final zoomDiff = (targetZoom - startZoom).abs();
    final durationMs =
        (zoomDiff * 120 + (latDiff + lngDiff) * 2).clamp(300, 2000).toInt();

    _animDuration = Duration(milliseconds: durationMs);
    _animStart = startCenter;
    _animEnd = target;
    _animStartZoom = startZoom;
    _animEndZoom = targetZoom;
    notifyListeners();
  }

  void animateToFitBounds(LatLngBounds bounds,
      {EdgeInsets padding = const EdgeInsets.all(50)}) {
    if (_mapController == null) return;
    final targetCamera =
        CameraFit.bounds(bounds: bounds, padding: padding).fit(_mapController!.camera);
    animateTo(targetCamera.center, targetCamera.zoom);
  }

  void zoomIn(double minZoom, double maxZoom) {
    _currentZoom = (_currentZoom + 1).clamp(minZoom, maxZoom);
    animateTo(_mapController?.camera.center ?? LatLng(0, 0), _currentZoom);
  }

  void zoomOut(double minZoom, double maxZoom) {
    _currentZoom = (_currentZoom - 1).clamp(minZoom, maxZoom);
    animateTo(_mapController?.camera.center ?? LatLng(0, 0), _currentZoom);
  }

  void resetView(LatLng center, double zoom) {
    _currentZoom = zoom;
    animateTo(center, zoom);
  }

  void updateZoom(double zoom) {
    _currentZoom = zoom;
  }
}
