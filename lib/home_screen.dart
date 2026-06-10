import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'tile_service.dart';
import 'tile_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // App State
  String? _tilesPath;
  bool _isLoadingTiles = true;
  String _loadingMessage = 'Loading map...';

  // Tracking
  List<LatLng> routePoints = [];
  bool isTracking = false;
  StreamSubscription<Position>? _locationSub;
  double totalDistance = 0;
  int seconds = 0;
  double currentSpeedKmh = 0;
  Timer? _timer;
  final MapController _mapController = MapController();

  static const LatLng fayoumUniversity = LatLng(29.3084, 30.8428);

  // Init
  @override
  void initState() {
    super.initState();
    _initTiles();
  }

  Future<void> _initTiles() async {
    try {
      setState(() => _loadingMessage = 'Extracting map (first time only)...');
      final path = await TileService.getTilesPath();
      setState(() {
        _tilesPath = path;
        _isLoadingTiles = false;
      });
    } catch (e) {
      setState(() => _loadingMessage = 'Error: $e');
    }
  }

  //Activity Type
  Map<String, dynamic> getActivityInfo(double speedKmh) {
    if (speedKmh < 1.0) {
      return {
        'label': 'Standing Still',
        'icon': Icons.accessibility_new,
        'color': Colors.grey,
      };
    } else if (speedKmh < 6.0) {
      return {
        'label': 'Walking',
        'icon': Icons.directions_walk,
        'color': Colors.green,
      };
    } else if (speedKmh < 10.0) {
      return {
        'label': 'Jogging',
        'icon': Icons.directions_run,
        'color': Colors.orange,
      };
    } else {
      return {'label': 'Running', 'icon': Icons.speed, 'color': Colors.red};
    }
  }

  //GPS Permission
  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Please enable GPS');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied');
        return false;
      }
    }
    return true;
  }

  //Start Tracking
  Future<void> startTracking() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    setState(() {
      isTracking = true;
      routePoints = [];
      totalDistance = 0;
      seconds = 0;
      currentSpeedKmh = 0;
    });

    //Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });

    // GPS Stream
    _locationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position pos) {
          final newPoint = LatLng(pos.latitude, pos.longitude);
          setState(() {
            if (routePoints.isNotEmpty) {
              totalDistance += Geolocator.distanceBetween(
                routePoints.last.latitude,
                routePoints.last.longitude,
                newPoint.latitude,
                newPoint.longitude,
              );
            }
            routePoints.add(newPoint);
            currentSpeedKmh = (pos.speed < 0 ? 0 : pos.speed) * 3.6;
          });
          _mapController.move(newPoint, 16);
        });
  }

  //Stop Tracking
  void stopTracking() {
    _locationSub?.cancel();
    _timer?.cancel();
    setState(() {
      isTracking = false;
      currentSpeedKmh = 0;
    });
    _showMessage('Tracking stopped');
  }

  //Helpers
  String get formattedTime {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get avgSpeedKmh => seconds > 0 ? (totalDistance / seconds) * 3.6 : 0.0;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  //Loading Screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              _loadingMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    if (_isLoadingTiles) return _buildLoadingScreen();

    final activityInfo = getActivityInfo(currentSpeedKmh);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Tracking - Fayoum U'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          //Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: fayoumUniversity,
              initialZoom: 15,
              minZoom: 12,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                tileProvider: OfflineTileProvider(_tilesPath!),
                urlTemplate: '{z}/{x}/{y}',
                userAgentPackageName: 'com.example.route_tracker',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              if (routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routePoints.first,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                    Marker(
                      point: routePoints.last,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          //Stats Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Activity Badge
                  if (isTracking) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (activityInfo['color'] as Color)
                            .withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activityInfo['color'] as Color,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activityInfo['icon'] as IconData,
                            color: activityInfo['color'] as Color,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            activityInfo['label'] as String,
                            style: TextStyle(
                              color: activityInfo['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard(
                        Icons.straighten,
                        '${(totalDistance / 1000).toStringAsFixed(2)} km',
                        'Distance',
                        Colors.blue,
                      ),
                      _statCard(
                        Icons.timer,
                        formattedTime,
                        'Time',
                        Colors.blue,
                      ),
                      if (isTracking)
                        _statCard(
                          Icons.speed,
                          '${currentSpeedKmh.toStringAsFixed(1)} km/h',
                          'Current Speed',
                          activityInfo['color'] as Color,
                        )
                      else
                        _statCard(
                          Icons.speed,
                          '${avgSpeedKmh.toStringAsFixed(1)} km/h',
                          'Avg Speed',
                          Colors.blue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Start/Stop Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isTracking ? stopTracking : startTracking,
                      icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        isTracking ? 'Stop Tracking' : 'Start Tracking',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Stat Card
  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
