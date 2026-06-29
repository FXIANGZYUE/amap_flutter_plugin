import 'amap_latlng.dart';

class LocationResult {
  final AmapLatLng location;
  final double? accuracy;
  final String? address;
  final String? district;
  final String? city;
  final String? province;
  final String? country;
  final String? provider;

  const LocationResult({
    required this.location,
    this.accuracy,
    this.address,
    this.district,
    this.city,
    this.province,
    this.country,
    this.provider,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    if (json.containsKey('latitude') && json.containsKey('longitude')) {
      lat = (json['latitude'] as num?)?.toDouble() ?? 0;
      lng = (json['longitude'] as num?)?.toDouble() ?? 0;
    }

    return LocationResult(
      location: AmapLatLng(lat, lng),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      address: json['address'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      country: json['country'] as String?,
      provider: json['provider'] as String?,
    );
  }
}
