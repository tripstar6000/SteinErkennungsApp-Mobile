import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/result.dart';
import '../../services/location_service.dart';
import '../../services/providers.dart';
import '../result/result_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  final picker = ImagePicker();
  final photos = <File>[];
  final labels = <String>['Gesamtansicht', 'Zweite Seite', 'Nahaufnahme / Bruchfläche'];
  bool busy = false;
  bool torch = false;
  bool allowRemote = false;
  bool useLocation = false;
  bool _initializing = false;
  bool _showingResult = false;
  int _cameraGeneration = 0;
  String status = 'Kamera wird vorbereitet …';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_showingResult) {
      unawaited(_initCamera());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseCamera();
      if (mounted) setState(() {});
    }
  }

  void _releaseCamera() {
    _cameraGeneration++;
    _initializing = false;
    final old = controller;
    controller = null;
    torch = false;
    if (old != null) unawaited(old.dispose());
  }

  Future<void> _initCamera() async {
    if (_initializing || controller != null || !mounted) return;
    _initializing = true;
    final generation = ++_cameraGeneration;
    CameraController? camera;
    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
      if (cameras.isEmpty) throw StateError('Keine Kamera gefunden.');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final next = CameraController(back, ResolutionPreset.high, enableAudio: false);
      camera = next;
      await next.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await next.dispose();
        return;
      }
      setState(() {
        controller = next;
        status = 'Mindestens zwei Perspektiven aufnehmen.';
      });
    } catch (_) {
      if (camera != null) await camera.dispose();
      if (mounted && generation == _cameraGeneration) {
        setState(() => status = 'Kamera nicht verfügbar. Bitte Kamerafreigabe prüfen oder die Galerie verwenden.');
      }
    } finally {
      if (generation == _cameraGeneration) _initializing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _capture() async {
    final camera = controller;
    if (camera == null || !camera.value.isInitialized || busy || photos.length >= 3) return;
    setState(() => busy = true);
    try {
      final shot = await camera.takePicture();
      if (mounted) setState(() => photos.add(File(shot.path)));
    } catch (_) {
      _message('Aufnahme fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pick() async {
    if (busy || photos.length >= 3) return;
    setState(() => busy = true);
    try {
      final selected = await picker.pickImage(source: ImageSource.gallery);
      if (selected != null && mounted) {
        setState(() => photos.add(File(selected.path)));
      }
    } catch (_) {
      _message('Das Foto konnte nicht geöffnet werden. Bitte Galeriefreigabe prüfen.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggleTorch() async {
    final camera = controller;
    if (camera == null || busy) return;
    final next = !torch;
    try {
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted && controller == camera) setState(() => torch = next);
    } catch (_) {
      _message('Dauerlicht wird von diesem Gerät nicht unterstützt.');
    }
  }

  Future<void> _guided180() async {
    final camera = controller;
    if (busy || camera == null || photos.isNotEmpty) return;
    setState(() => busy = true);
    try {
      for (var i = 0; i < 3; i++) {
        if (!mounted || controller != camera) return;
        setState(() => status = switch (i) {
          0 => '0°: Vorderseite ruhig halten …',
          1 => '90°: Stein etwa halb drehen …',
          _ => '180°: Rückseite ruhig halten …',
        });
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted || controller != camera) return;
        final shot = await camera.takePicture();
        if (!mounted) return;
        setState(() => photos.add(File(shot.path)));
      }
      if (mounted) setState(() => status = '180°-Sequenz abgeschlossen.');
    } catch (_) {
      _message('Aufnahmesequenz unterbrochen. Einzelne Fotos können ergänzt werden.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _analyse() async {
    if (photos.length < 2 || busy) return;
    setState(() {
      busy = true;
      status = 'Bilder werden analysiert …';
    });
    try {
      ReducedLocation? location;
      if (useLocation) {
        try {
          location = await ref.read(locationServiceProvider).currentReducedLocation();
        } catch (_) {
          _message('Standort nicht verfügbar. Die Analyse wird ohne Standort fortgesetzt.');
        }
      }
      if (!mounted) return;
      final images = List<File>.of(photos);
      final result = await ref.read(scanRepositoryProvider).identify(
        images: images,
        perspectives: labels.take(images.length).toList(),
        reducedLocation: location?.apiValue,
        allowRemote: allowRemote,
      );
      if (!mounted) return;
      switch (result) {
        case AppSuccess(value: final value):
          _showingResult = true;
          _releaseCamera();
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              result: value,
              imagePaths: images.map((e) => e.path).toList(),
              latitude: location?.latitude,
              longitude: location?.longitude,
            ),
          ));
          _showingResult = false;
          if (mounted) unawaited(_initCamera());
        case AppFailure(message: final message):
          _message(message);
      }
    } catch (_) {
      _message('Die Analyse konnte nicht abgeschlossen werden. Deine Fotos bleiben für einen neuen Versuch erhalten.');
    } finally {
      if (mounted) setState(() {
        busy = false;
        status = 'Bereit für einen neuen Scan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    final cameraReady = camera != null && camera.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Präzisions-Scan'),
        actions: [
          IconButton(
            onPressed: cameraReady && !busy ? _toggleTorch : null,
            icon: Icon(torch ? Icons.flashlight_on : Icons.flashlight_off),
            tooltip: 'Kameralicht',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            flex: 2,
            child: cameraReady
                ? Center(child: CameraPreview(camera))
                : Center(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(status, textAlign: TextAlign.center),
                  )),
          ),
          Flexible(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Semantics(liveRegion: true, child: Text(status)),
                if (busy) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Row(children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: i < photos.length
                            ? Stack(fit: StackFit.expand, children: [
                                Image.file(photos[i], fit: BoxFit.cover,
                                  semanticLabel: labels[i],
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                                Align(alignment: Alignment.topRight, child: IconButton.filled(
                                  onPressed: busy ? null : () => setState(() => photos.removeAt(i)),
                                  tooltip: 'Foto ${i + 1} entfernen',
                                  icon: const Icon(Icons.close),
                                )),
                              ])
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text(labels[i], textAlign: TextAlign.center)),
                              ),
                      ),
                    )),
                ]),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: busy || photos.length >= 3 ? null : _pick,
                    icon: const Icon(Icons.photo_library), label: const Text('Galerie'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(
                    onPressed: busy || !cameraReady || photos.length >= 3 ? null : _capture,
                    icon: const Icon(Icons.camera), label: const Text('Aufnehmen'),
                  )),
                ]),
                OutlinedButton(
                  onPressed: busy || !cameraReady || photos.isNotEmpty ? null : _guided180,
                  child: const Text('Automatische 180°-Sequenz'),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Online-Erkennung erlauben'),
                  subtitle: const Text('Ohne nutzbares Offline-Modell werden die ausgewählten Fotos an den Erkennungsserver gesendet.'),
                  value: allowRemote,
                  onChanged: busy ? null : (value) => setState(() => allowRemote = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ungefähren Standort verwenden'),
                  subtitle: const Text('Optional. Nur auf zwei Dezimalstellen gerundete Koordinaten werden verwendet und bei Online-Erkennung übertragen.'),
                  value: useLocation,
                  onChanged: busy ? null : (value) => setState(() => useLocation = value),
                ),
                FilledButton.icon(
                  onPressed: photos.length >= 2 && !busy ? _analyse : null,
                  icon: const Icon(Icons.search),
                  label: Text(busy ? 'Bitte warten …' : 'Stein analysieren'),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
