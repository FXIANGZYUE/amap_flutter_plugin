import 'amap_latlng.dart';

class PoiItem {
  final String id;
  final String name;
  final String address;
  final AmapLatLng location;
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
