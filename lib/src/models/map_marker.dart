import 'package:flutter/widgets.dart';
import 'amap_latlng.dart';

class MapMarker {
  final AmapLatLng point;
  final Widget child;
  final double width;
  final double height;

  const MapMarker({
    required this.point,
    required this.child,
    this.width = 40,
    this.height = 40,
  });
}
