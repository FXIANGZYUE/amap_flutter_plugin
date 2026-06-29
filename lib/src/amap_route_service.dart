import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/amap_latlng.dart';
import 'models/map_route.dart';
import 'models/poi_item.dart';

class AmapRouteService {
  final String apiKey;

  const AmapRouteService({required this.apiKey});

  Future<AmapRouteResult?> getDrivingRoute({
    required AmapLatLng origin,
    required AmapLatLng destination,
  }) async {
    final originStr = '${origin.longitude},${origin.latitude}';
    final destStr = '${destination.longitude},${destination.latitude}';
    final url = Uri.parse(
      'https://restapi.amap.com/v3/direction/driving'
      '?origin=$originStr&destination=$destStr&key=$apiKey&extensions=base',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] != '1') return null;

    final path = data['route']['paths'][0] as Map<String, dynamic>;
    final distance = int.parse(path['distance'] as String);
    final steps = path['steps'] as List<dynamic>;
    final polyline = steps
        .map<String>(
          (step) => (step as Map<String, dynamic>)['polyline'] as String,
        )
        .join(';');

    final points = <AmapLatLng>[];
    for (final point in polyline.split(';')) {
      final parts = point.split(',');
      points.add(AmapLatLng(double.parse(parts[1]), double.parse(parts[0])));
    }

    return AmapRouteResult(points: points, distance: distance);
  }

  Future<AmapRouteResult?> getWalkingRoute({
    required AmapLatLng origin,
    required AmapLatLng destination,
  }) async {
    final originStr = '${origin.longitude},${origin.latitude}';
    final destStr = '${destination.longitude},${destination.latitude}';
    final url = Uri.parse(
      'https://restapi.amap.com/v3/direction/walking'
      '?origin=$originStr&destination=$destStr&key=$apiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] != '1') return null;

    final path = data['route']['paths'][0] as Map<String, dynamic>;
    final distance = int.parse(path['distance'] as String);
    final steps = path['steps'] as List<dynamic>;
    final polyline = steps
        .map<String>(
          (step) => (step as Map<String, dynamic>)['polyline'] as String,
        )
        .join(';');

    final points = <AmapLatLng>[];
    for (final point in polyline.split(';')) {
      final parts = point.split(',');
      points.add(AmapLatLng(double.parse(parts[1]), double.parse(parts[0])));
    }

    return AmapRouteResult(points: points, distance: distance);
  }
}

class AmapPoiService {
  final String apiKey;

  const AmapPoiService({required this.apiKey});

  Future<List<PoiItem>> search({
    required String keywords,
    AmapLatLng? location,
    int radius = 3000,
    int pageSize = 20,
  }) async {
    final params = {
      'key': apiKey,
      'keywords': keywords,
      'offset': pageSize.toString(),
      'extensions': 'all',
    };
    if (location != null) {
      params['location'] = '${location.longitude},${location.latitude}';
      params['sortrule'] = 'distance';
      params['radius'] = radius.toString();
    }

    final url = Uri.https('restapi.amap.com', '/v3/place/text', params);
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] != '1' || data['pois'] == null) return [];

    final pois = data['pois'] as List<dynamic>;
    return pois.map((poi) {
      final loc = (poi['location'] as String).split(',');
      final tel = poi['tel'];
      String? telStr;
      if (tel is String) {
        telStr = tel;
      } else if (tel is List && tel.isNotEmpty) {
        telStr = tel.first.toString();
      }
      return PoiItem(
        id: poi['id'] as String,
        name: poi['name'] as String,
        address: poi['address'] as String? ?? '',
        location: AmapLatLng(double.parse(loc[1]), double.parse(loc[0])),
        type: poi['type'] as String? ?? '',
        tel: telStr,
      );
    }).toList();
  }
}
