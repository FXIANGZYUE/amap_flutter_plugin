import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'amap_location_stub.dart';
import 'models/location_result.dart';

class AmapLocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.amap_flutter_plugin/location',
  );

  final bool _isWeb;
  final WebLocationHelper _webHelper = WebLocationHelper();
  int? _watchId;

  AmapLocationService({required String apiKey}) : _isWeb = kIsWeb {
    if (!_isWeb) {
      _channel.invokeMethod('init', {'apiKey': apiKey});
    }
  }

  Future<LocationResult?> getLocation() async {
    if (_isWeb) {
      return _webGetLocation();
    }
    return _nativeGetLocation();
  }

  Future<LocationResult?> _webGetLocation() async {
    try {
      final result = await _webHelper.getCurrentPosition();
      if (result['errorCode'] != 0) return null;
      return LocationResult.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  Future<LocationResult?> _nativeGetLocation() async {
    try {
      final result = await _channel.invokeMethod('getLocation');
      if (result == null) return null;
      return LocationResult.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      return null;
    }
  }

  void startLocationStream({
    required void Function(LocationResult) onLocationUpdate,
  }) {
    if (_isWeb) {
      _watchId = _webHelper.watchPosition((data) {
        final result = LocationResult.fromJson(data);
        onLocationUpdate(result);
      });
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLocationUpdate') {
        final data = Map<String, dynamic>.from(call.arguments);
        final result = LocationResult.fromJson(data);
        onLocationUpdate(result);
      }
    });

    _channel.invokeMethod('startLocationStream');
  }

  void stopLocationStream() {
    if (_isWeb) {
      if (_watchId != null) {
        _webHelper.clearWatch(_watchId!);
        _watchId = null;
      }
      return;
    }
    _channel.invokeMethod('stopLocationStream');
  }

  void dispose() {
    stopLocationStream();
    if (!_isWeb) {
      _channel.invokeMethod('dispose');
    }
  }
}
