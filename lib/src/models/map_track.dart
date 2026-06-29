import 'package:flutter/material.dart';
import 'amap_latlng.dart';

class MapTrack {
  final List<AmapLatLng> points;
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
