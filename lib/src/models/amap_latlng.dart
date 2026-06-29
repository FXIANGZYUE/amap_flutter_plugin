class AmapLatLng {
  final double latitude;
  final double longitude;

  const AmapLatLng(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  factory AmapLatLng.fromJson(Map<String, dynamic> json) {
    return AmapLatLng(
      (json['lat'] as num?)?.toDouble() ?? 0,
      (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmapLatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'AmapLatLng($latitude, $longitude)';
}
