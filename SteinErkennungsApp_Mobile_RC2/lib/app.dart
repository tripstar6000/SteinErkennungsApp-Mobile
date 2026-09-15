import 'package:flutter/material.dart';

import 'features/collection/collection_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/map_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_screen.dart';

class SteinApp extends StatefulWidget {
  const SteinApp({super.key});

  @override
  State<SteinApp> createState() => _SteinAppState();
}

class _SteinAppState extends State<SteinApp> {
  var index = 0;

  void _select(int value) => setState(() => index = value);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onScan: () => _select(2),
        onDiscover: () => _select(1),
        onCollection: () => _select(3),
        onMap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        ),
      ),
      const DiscoverScreen(),
      const ScanScreen(),
      const CollectionScreen(),
      const SettingsScreen(),
    ];

    return MaterialApp(
      title: 'SteinErkennungsApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: Scaffold(
        body: IndexedStack(index: index, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Entdecken'),
            NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Scan'),
            NavigationDestination(icon: Icon(Icons.collections), label: 'Sammlung'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Einstellungen'),
          ],
        ),
      ),
    );
  }
}
