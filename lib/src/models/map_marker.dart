import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

class MapMarker {
  final LatLng point;
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
