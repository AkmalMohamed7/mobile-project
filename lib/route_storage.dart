import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';

// Route model
class SavedRoute {
  final String id;
  final DateTime date;
  final double distanceKm;
  final int durationSeconds;
  final double avgSpeedKmh;
  final List<LatLng> points;

  SavedRoute({
    required this.id,
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.points,
  });

  // Convert to JSON for saving
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'avgSpeedKmh': avgSpeedKmh,
    'points': points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
  };

  // Convert from JSON for loading
  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
    id: json['id'],
    date: DateTime.parse(json['date']),
    distanceKm: json['distanceKm'],
    durationSeconds: json['durationSeconds'],
    avgSpeedKmh: json['avgSpeedKmh'],
    points: (json['points'] as List)
        .map((p) => LatLng(p['lat'], p['lng']))
        .toList(),
  );

  // Format duration
  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Format date
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Save/load service
class RouteStorage {
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/routes.json');
  }

  // Save new route
  static Future<void> saveRoute(SavedRoute route) async {
    final routes = await loadRoutes();
    routes.insert(0, route); // newest first
    final file = await _getFile();
    final json = routes.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
  }

  // Load all routes
  static Future<List<SavedRoute>> loadRoutes() async {
    try {
      final file = await _getFile();
      if (!file.existsSync()) return [];
      final content = await file.readAsString();
      final List json = jsonDecode(content);
      return json.map((j) => SavedRoute.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete route
  static Future<void> deleteRoute(String id) async {
    final routes = await loadRoutes();
    routes.removeWhere((r) => r.id == id);
    final file = await _getFile();
    final json = routes.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
  }
}
