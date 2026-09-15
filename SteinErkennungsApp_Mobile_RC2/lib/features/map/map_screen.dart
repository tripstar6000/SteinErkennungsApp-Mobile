import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../services/providers.dart';
import '../../shared/app_scaffold.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? location;
  String status = 'Standort noch nicht geladen.';

  Future<void> _locate() async {
    final pos = await ref.read(locationServiceProvider).currentReducedLocation();
    if (!mounted) return;
    setState(() {
      if (pos == null) {
        status = 'Standort nicht freigegeben oder nicht verfuegbar.';
      } else {
        location = LatLng(pos.latitude, pos.longitude);
        status =
            'Reduzierte Position: ${pos.latitude.toStringAsFixed(2)}, '
            '${pos.longitude.toStringAsFixed(2)}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = location ?? const LatLng(51.36, 7.47);
    return AppScaffold(
      title: 'Karte',
      actions: [
        IconButton(onPressed: _locate, icon: const Icon(Icons.my_location)),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(status),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: location == null ? 8 : 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'de.steinerkennungsapp.mobile',
                ),
                if (location != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          size: 42,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: ColoredBox(
                    color: Colors.white70,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Die Karte zeigt keine exakten sensiblen Fundstellen. '
              'Regionale Geologie wird getrennt von der Foto-KI bewertet.',
            ),
          ),
        ],
      ),
    );
  }
}
