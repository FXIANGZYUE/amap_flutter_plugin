import 'package:flutter/material.dart';
import 'package:amap_flutter_plugin/amap_flutter_plugin.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMap Plugin Example',
      home: const MapExamplePage(),
    );
  }
}

class MapExamplePage extends StatefulWidget {
  const MapExamplePage({super.key});

  @override
  State<MapExamplePage> createState() => _MapExamplePageState();
}

class _MapExamplePageState extends State<MapExamplePage> {
  final _amapController = AmapController();
  final _amapKey = 'YOUR_AMAP_KEY';

  final _origin = const LatLng(39.9042, 116.4074);
  final _destination = const LatLng(39.9087, 116.3975);

  List<MapRoute> _routes = [];
  bool _isLoading = false;

  final _historyTrack = const [
    LatLng(39.9042, 116.4074),
    LatLng(39.9050, 116.4060),
    LatLng(39.9058, 116.4048),
    LatLng(39.9065, 116.4035),
    LatLng(39.9072, 116.4020),
    LatLng(39.9078, 116.4010),
    LatLng(39.9085, 116.4000),
    LatLng(39.9090, 116.3990),
    LatLng(39.9095, 116.3982),
    LatLng(39.9087, 116.3975),
  ];

  Future<void> _planRoute() async {
    setState(() {
      _isLoading = true;
      _routes = [];
    });

    try {
      final routeService = AmapRouteService(apiKey: _amapKey);
      final result = await routeService.getDrivingRoute(
        origin: _origin,
        destination: _destination,
      );

      if (result != null) {
        setState(() {
          _routes = [MapRoute(points: result.points, color: Colors.blue)];
        });

        if (result.points.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(result.points);
          _amapController.animateToFitBounds(bounds);
        }
      }
    } catch (e) {
      debugPrint('Route planning failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AMap Plugin Example')),
      body: Stack(
        children: [
          AmapWidget(
            controller: _amapController,
            tracks: [
              MapTrack(
                points: _historyTrack,
                color: Colors.deepOrange,
                showDots: true,
                dotColor: Colors.deepOrange,
                dotSize: 10,
              ),
            ],
            routes: _routes,
            showZoomControls: true,
          ),
          Positioned(
            left: 16,
            bottom: 100,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _planRoute,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.directions),
              label: Text(_isLoading ? '规划中...' : '驾车路线'),
            ),
          ),
        ],
      ),
    );
  }
}
