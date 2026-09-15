import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/result.dart';
import '../../services/providers.dart';
import '../result/result_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? controller;
  final picker = ImagePicker();
  final photos = <File>[];
  final labels = <String>['Gesamtansicht', 'Zweite Seite', 'Nahaufnahme / Bruchflaeche'];
  bool busy = false;
  bool torch = false;
  bool autoZoom = true;
  String status = 'Kamera wird vorbereitet …';

  @override
  void initState() {
    super.initState();
    unawaited(_initCamera());
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Keine Kamera gefunden.');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await c.initialize();
      if (autoZoom) {
        final min = await c.getMinZoomLevel();
        final max = await c.getMaxZoomLevel();
        final target = (min + 0.5).clamp(min, max);
        await c.setZoomLevel(target);
      }
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        controller = c;
        status = 'Mindestens zwei Perspektiven aufnehmen.';
      });
    } catch (e) {
      if (mounted) setState(() => status = 'Kamera nicht verfuegbar: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final c = controller;
    if (c == null || !c.value.isInitialized || busy || photos.length >= 3) return;
    setState(() => busy = true);
    try {
      final shot = await c.takePicture();
      setState(() => photos.add(File(shot.path)));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pick() async {
    if (photos.length >= 3) return;
    final selected = await picker.pickImage(source: ImageSource.gallery);
    if (selected != null && mounted) {
      setState(() => photos.add(File(selected.path)));
    }
  }

  Future<void> _toggleTorch() async {
    final c = controller;
    if (c == null) return;
    final next = !torch;
    try {
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => torch = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dauerlicht wird von diesem Geraet nicht unterstuetzt.')),
        );
      }
    }
  }

  Future<void> _guided180() async {
    if (busy || controller == null) return;
    setState(() {
      busy = true;
      status = '180°-Scan: Stein langsam drehen. Startaufnahme …';
    });
    try {
      photos.clear();
      for (var i = 0; i < 3; i++) {
        if (!mounted) return;
        setState(() {
          status = switch (i) {
            0 => '0°: Vorderseite ruhig halten …',
            1 => '90°: Stein etwa halb drehen …',
            _ => '180°: Rueckseite ruhig halten …',
          };
        });
        await Future<void>.delayed(const Duration(seconds: 2));
        final shot = await controller!.takePicture();
        photos.add(File(shot.path));
        if (mounted) setState(() {});
      }
      if (mounted) setState(() => status = '180°-Sequenz abgeschlossen: 3 Perspektiven.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _analyse() async {
    if (photos.length < 2 || busy) return;
    setState(() {
      busy = true;
      status = 'Standort und Bildanalyse werden vorbereitet …';
    });
    try {
      final location =
          await ref.read(locationServiceProvider).currentReducedLocation();
      final result = await ref.read(scanRepositoryProvider).identify(
            images: photos,
            perspectives: labels.take(photos.length).toList(),
            reducedLocation: location?.apiValue,
            preferOffline: true,
          );
      if (!mounted) return;
      switch (result) {
        case AppSuccess(value: final value):
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                result: value,
                imagePaths: photos.map((e) => e.path).toList(),
                latitude: location?.latitude,
                longitude: location?.longitude,
              ),
            ),
          );
        case AppFailure(message: final message):
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          status = 'Bereit fuer einen neuen Scan.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praezisions-Scan'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(torch ? Icons.flashlight_on : Icons.flashlight_off),
            tooltip: 'Kameralicht',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: c != null && c.value.isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(c),
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white70,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: Text(status)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(status),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: i < photos.length
                                  ? Image.file(photos[i], fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        labels[i],
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _pick,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galerie'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy ? null : _capture,
                        icon: const Icon(Icons.camera),
                        label: const Text('Aufnehmen'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : _guided180,
                        child: const Text('Automatische 180°-Sequenz'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            photos.length >= 2 && !busy ? _analyse : null,
                        child: const Text('Analysieren'),
                      ),
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
}
