import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../shared/app_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String status = 'Noch nichts ausgefuehrt.';

  Future<void> _modelStatus() async {
    final data = await ref.read(modelManagerProvider).status();
    setState(() => status = const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> _core() async {
    try {
      final result = await ref.read(offlinePackageProvider).installCore();
      setState(() => status = 'Offline-Kernpaket installiert: $result');
    } catch (e) {
      setState(() => status = 'Offline-Kernpaket fehlgeschlagen: $e');
    }
  }

  Future<void> _region() async {
    try {
      final result = await ref.read(offlinePackageProvider).installRegion();
      setState(() => status = 'Regionalpaket installiert: $result');
    } catch (e) {
      setState(() => status = 'Regionalpaket fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Einstellungen',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(
              title: Text('Datenschutz'),
              subtitle: Text(
                'Standort wird nur nach Freigabe verwendet und vor Uebertragung '
                'auf etwa 2 Dezimalstellen reduziert. Bilder werden nur fuer '
                'einen Scan an die Online-API gesendet, wenn kein lokales '
                'Modell verfuegbar ist.',
              ),
            ),
            FilledButton(
              onPressed: _core,
              child: const Text('Offline-Kernpaket installieren'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _region,
              child: const Text('Regionalpaket Deutschland installieren'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _modelStatus,
              child: const Text('Offline-Modellstatus pruefen'),
            ),
            const SizedBox(height: 12),
            SelectableText(status),
            const Divider(),
            const Text(
              'Produktionsregel: Kein API-Key wird im Mobile-Client gespeichert. '
              'Secrets gehoeren ausschliesslich ins Backend.',
            ),
          ],
        ),
      );
}
