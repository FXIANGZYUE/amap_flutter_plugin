import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'amap_location_service.dart';
import 'models/amap_latlng.dart';
import 'models/location_result.dart';

class AmapController extends ChangeNotifier {
  MethodChannel? _channel;
  AmapLocationService? _locationService;
  AmapLatLng _center = const AmapLatLng(39.9042, 116.4074);
  double _zoom = 18.0;
  LocationResult? _currentLocation;

  AmapLatLng get center => _center;
  double get zoom => _zoom;
  LocationResult? get currentLocation => _currentLocation;

  void bindChannel(MethodChannel channel) {
    _channel = channel;
  }

  void setApiKey(String apiKey) {
    _locationService?.dispose();
    _locationService = AmapLocationService(apiKey: apiKey);
  }

  Future<LocationResult?> getLocation() async {
    return _locationService?.getLocation();
  }

  void startLocationStream() {
    _locationService?.startLocationStream(onLocationUpdate: updateLocation);
  }

  void stopLocationStream() {
    _locationService?.stopLocationStream();
  }

  void updateLocation(LocationResult location) {
    _currentLocation = location;
    notifyListeners();
  }

  void centerOnLocation() {
    if (_currentLocation != null) {
      animateTo(_currentLocation!.location, 16.0);
    }
  }

  void animateTo(AmapLatLng target, double targetZoom) {
    _channel?.invokeMethod('moveCamera', {
      'lat': target.latitude,
      'lng': target.longitude,
      'zoom': targetZoom,
      'animate': true,
    });
    _center = target;
    _zoom = targetZoom;
    notifyListeners();
  }

  void animateToFitBounds(List<AmapLatLng> points, {double padding = 50}) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoom = (14.0 - (maxDiff * 5)).clamp(3.0, 20.0);
    animateTo(AmapLatLng(centerLat, centerLng), zoom);
  }

  void zoomIn(double minZoom, double maxZoom) {
    _zoom = (_zoom + 1).clamp(minZoom, maxZoom);
    _channel?.invokeMethod('setZoom', {'zoom': _zoom});
    notifyListeners();
  }

  void zoomOut(double minZoom, double maxZoom) {
    _zoom = (_zoom - 1).clamp(minZoom, maxZoom);
    _channel?.invokeMethod('setZoom', {'zoom': _zoom});
    notifyListeners();
  }

  void resetView(AmapLatLng center, double zoom) {
    _zoom = zoom;
    animateTo(center, zoom);
  }

  void onCameraIdle(double lat, double lng, double zoom) {
    _center = AmapLatLng(lat, lng);
    _zoom = zoom;
    notifyListeners();
  }

  void updateZoom(double zoom) {
    _zoom = zoom;
  }

  @override
  void dispose() {
    _locationService?.dispose();
    super.dispose();
  }
}
