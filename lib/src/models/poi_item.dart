import 'package:latlong2/latlong.dart';

class PoiItem {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String type;
  final String? tel;

  const PoiItem({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.type,
    this.tel,
  });
}
