import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapRoute {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final bool showHighlight;
  final Color? highlightColor;
  final double highlightWidth;

  const MapRoute({
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 5.0,
    this.showHighlight = true,
    this.highlightColor,
    this.highlightWidth = 12.0,
  });
}

class AmapRouteResult {
  final List<LatLng> points;
  final int distance;

  const AmapRouteResult({
    required this.points,
    required this.distance,
  });

  String get distanceText => '${(distance / 1000).toStringAsFixed(1)} km';
}
