# Amap Flutter Plugin

A Flutter plugin for integrating Amap (Gaode Maps) into your Flutter applications. This plugin provides map display, route planning, POI search, and track recording features.

## Features

- **Map Display** - Render Amap tiles with smooth zoom and pan gestures
- **Animated Navigation** - Smooth animated transitions between locations
- **Route Planning** - Driving and walking route calculation via Amap API
- **POI Search** - Search for places, restaurants, hotels, and more
- **Custom Markers** - Add custom markers with labels to the map
- **Track Recording** - Display GPS tracks with dot indicators
- **Cross-Platform** - Works on Android, iOS, Web, Windows, macOS, and Linux

## Getting Started

### Prerequisites

1. Get an Amap API key from [Amap Open Platform](https://console.amap.com)
2. Register an application and obtain a **Web Service** type key

### Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  amap_flutter_plugin:
    git:
      url: https://github.com/FXIANGZYUE/amap_flutter_plugin.git
      ref: main
```

Or use a local path:

```yaml
dependencies:
  amap_flutter_plugin:
    path: /path/to/amap_flutter_plugin
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Map

Display a simple map centered on a location:

```dart
import 'package:amap_flutter_plugin/amap_flutter_plugin.dart';
import 'package:latlong2/latlong.dart';

class MyMapPage extends StatelessWidget {
  const MyMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmapWidget(
        center: LatLng(39.9042, 116.4074), // Beijing
        zoom: 14.0,
      ),
    );
  }
}
```

### Map with Controller

Use a controller to programmatically control the map:

```dart
class MyMapPage extends StatefulWidget {
  const MyMapPage({super.key});

  @override
  State<MyMapPage> createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  final _controller = AmapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmapWidget(
        controller: _controller,
        center: LatLng(39.9042, 116.4074),
        zoom: 14.0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Animate to a new location
          _controller.animateTo(
            LatLng(39.9087, 116.3975),
            16.0,
          );
        },
        child: const Icon(Icons.location_on),
      ),
    );
  }
}
```

### Route Planning

Calculate and display driving routes:

```dart
final routeService = AmapRouteService(apiKey: 'YOUR_API_KEY');

// Get driving route
final result = await routeService.getDrivingRoute(
  origin: LatLng(39.9042, 116.4074),
  destination: LatLng(39.9087, 116.3975),
);

if (result != null) {
  // Display route on map
  setState(() {
    _routes = [
      MapRoute(
        points: result.points,
        color: Colors.blue,
      ),
    ];
  });

  // Show distance
  print('Distance: ${result.distanceText}');
}
```

### POI Search

Search for places and display them as markers:

```dart
final poiService = AmapPoiService(apiKey: 'YOUR_API_KEY');

// Search for restaurants
final pois = await poiService.search(
  keywords: 'restaurant',
  location: LatLng(39.9042, 116.4074),
  radius: 5000, // Search radius in meters
);

// Display as markers
setState(() {
  _markers = pois.map((poi) {
    return MapMarker(
      point: poi.location,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(poi.name),
          Icon(Icons.location_on, color: Colors.red),
        ],
      ),
    );
  }).toList();
});
```

### Track Recording

Display a GPS track with dot indicators:

```dart
AmapWidget(
  center: LatLng(39.9042, 116.4074),
  tracks: [
    MapTrack(
      points: [
        LatLng(39.9042, 116.4074),
        LatLng(39.9050, 116.4060),
        LatLng(39.9058, 116.4048),
        // ... more points
      ],
      color: Colors.orange,
      showDots: true,
      dotColor: Colors.deepOrange,
      dotSize: 10,
    ),
  ],
)
```

## Widget Parameters

### AmapWidget

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `center` | `LatLng` | `LatLng(39.9042, 116.4074)` | Initial map center |
| `zoom` | `double` | `14.0` | Initial zoom level |
| `minZoom` | `double` | `3.0` | Minimum zoom level |
| `maxZoom` | `double` | `20.0` | Maximum zoom level |
| `controller` | `AmapController?` | `null` | Map controller |
| `tracks` | `List<MapTrack>` | `[]` | GPS tracks to display |
| `routes` | `List<MapRoute>` | `[]` | Routes to display |
| `markers` | `List<MapMarker>` | `[]` | Custom markers |
| `showZoomControls` | `bool` | `true` | Show zoom buttons |

### AmapController Methods

| Method | Description |
|--------|-------------|
| `animateTo(LatLng, double)` | Animate to location with zoom |
| `animateToFitBounds(LatLngBounds)` | Fit map to show all points |
| `zoomIn(double, double)` | Zoom in one level |
| `zoomOut(double, double)` | Zoom out one level |
| `resetView(LatLng, double)` | Reset to initial view |

### MapTrack

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `points` | `List<LatLng>` | required | Track points |
| `color` | `Color` | `Colors.blue` | Line color |
| `strokeWidth` | `double` | `3.0` | Line width |
| `showDots` | `bool` | `false` | Show dots at each point |
| `dotColor` | `Color?` | `null` | Dot color |
| `dotSize` | `double` | `10` | Dot size |

### MapRoute

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `points` | `List<LatLng>` | required | Route points |
| `color` | `Color` | `Colors.blue` | Line color |
| `strokeWidth` | `double` | `5.0` | Line width |
| `showHighlight` | `bool` | `true` | Show highlight stroke |
| `highlightColor` | `Color?` | `null` | Highlight color |
| `highlightWidth` | `double` | `12.0` | Highlight width |

## API Key Setup

1. Visit [Amap Open Platform](https://console.amap.com)
2. Create an account or log in
3. Go to "Application Management" > "My Applications"
4. Create a new application
5. Add a key with **Web Service** platform type
6. Copy the generated key

## Platform Support

| Platform | Status |
|----------|--------|
| Android | Supported |
| iOS | Supported |
| Web | Supported |
| Windows | Supported |
| macOS | Supported |
| Linux | Supported |

## Requirements

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.12.0

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please [create an issue](https://github.com/FXIANGZYUE/amap_flutter_plugin/issues).
