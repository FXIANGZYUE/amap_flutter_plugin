import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapTrack {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final bool showDots;
  final Color? dotColor;
  final double dotSize;

  const MapTrack({
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 3.0,
    this.showDots = false,
    this.dotColor,
    this.dotSize = 10,
  });
}
