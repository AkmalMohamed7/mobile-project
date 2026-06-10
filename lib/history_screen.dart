import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'route_storage.dart';
import 'tile_provider.dart';

class HistoryScreen extends StatefulWidget {
  final String tilesPath;
  const HistoryScreen({super.key, required this.tilesPath});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SavedRoute> routes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final loaded = await RouteStorage.loadRoutes();
    setState(() {
      routes = loaded;
      isLoading = false;
    });
  }

  Future<void> _deleteRoute(String id) async {
    await RouteStorage.deleteRoute(id);
    _loadRoutes();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Route deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : routes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved routes yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return _RouteCard(
                  route: route,
                  tilesPath: widget.tilesPath,
                  onDelete: () => _deleteRoute(route.id),
                );
              },
            ),
    );
  }
}

// Route card
class _RouteCard extends StatelessWidget {
  final SavedRoute route;
  final String tilesPath;
  final VoidCallback onDelete;

  const _RouteCard({
    required this.route,
    required this.tilesPath,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Map preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 150,
              child: route.points.isNotEmpty
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: route.points[route.points.length ~/ 2],
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none, // map is not interactive
                        ),
                      ),
                      children: [
                        TileLayer(
                          tileProvider: OfflineTileProvider(tilesPath),
                          urlTemplate: '{z}/{x}/{y}',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: route.points,
                              color: Colors.blue,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      ],
                    )
                  : const ColoredBox(color: Colors.grey),
            ),
          ),

          // Route information
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      route.formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Route?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(
                      Icons.straighten,
                      '${route.distanceKm.toStringAsFixed(2)} km',
                      'Distance',
                    ),
                    _stat(Icons.timer, route.formattedDuration, 'Time'),
                    _stat(
                      Icons.speed,
                      '${route.avgSpeedKmh.toStringAsFixed(1)} km/h',
                      'Speed',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
