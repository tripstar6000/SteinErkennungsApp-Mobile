import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onScan,
    required this.onDiscover,
    required this.onCollection,
    required this.onMap,
  });

  final VoidCallback onScan;
  final VoidCallback onDiscover;
  final VoidCallback onCollection;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'SteinErkennungsApp',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Mehrbild-Erkennung · physischer Nachtest · Standortkontext · Offline-first',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Stein scannen'),
            ),
          ),
          const SizedBox(height: 16),
          _Tile(
            icon: Icons.search,
            title: 'Entdecken',
            subtitle: 'Kernkatalog durchsuchen',
            onTap: onDiscover,
          ),
          _Tile(
            icon: Icons.collections_bookmark,
            title: 'Sammlung',
            subtitle: 'Gespeicherte Scans und Favoriten',
            onTap: onCollection,
          ),
          _Tile(
            icon: Icons.map,
            title: 'Karte',
            subtitle: 'Standort und regionale Geologie',
            onTap: onMap,
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hinweis: Eine Fotoerkennung ist eine moegliche Bestimmung, '
                'keine zweifelsfreie mineralogische Analyse.',
              ),
            ),
          ),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
