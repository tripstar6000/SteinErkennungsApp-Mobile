import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/models.dart';
import 'model_manager.dart';

class LocalInferenceUnavailable implements Exception {
  const LocalInferenceUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocalInferenceService {
  LocalInferenceService(this._models);
  final ModelManager _models;
  Interpreter? _interpreter;
  List<String> _labels = const [];

  Future<void> initialize() async {
    await _models.ensureBundledModelInstalled();
    if (!await _models.isInstalledAndValid()) {
      throw const LocalInferenceUnavailable(
        'Kein fachlich validiertes Offline-Modell installiert.',
      );
    }
    _interpreter ??= Interpreter.fromFile(await _models.modelFile());
    _labels = await _models.readLabels();
    if (_labels.length < 2) {
      throw const LocalInferenceUnavailable(
        'Offline-Modell besitzt keine gueltige Klassenliste.',
      );
    }
  }

  Future<List<ScanPrediction>> classify(File imageFile) async {
    await initialize();
    final interpreter = _interpreter!;
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final shape = inputTensor.shape;

    if (shape.length != 4 || shape[0] != 1 || shape.last != 3) {
      throw LocalInferenceUnavailable(
        'Nicht unterstuetzte Modell-Eingabeform: ${shape.join('x')}',
      );
    }
    if (inputTensor.type != TensorType.float32) {
      throw LocalInferenceUnavailable(
        'Installiertes Modell nutzt ${inputTensor.type}; '
        'diese Release-Runtime ist fuer Float32-NHWC freigegeben.',
      );
    }

    final height = shape[1];
    final width = shape[2];
    final decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) {
      throw const FormatException('Bild konnte nicht dekodiert werden.');
    }
    final resized = img.copyResize(
      img.bakeOrientation(decoded),
      width: width,
      height: height,
    );

    // MobileNetV3 training pipeline exports a model whose input is RGB float32
    // in [0,255] and whose preprocessing layer is part of the model graph.
    final input = List.generate(
      1,
      (_) => List.generate(
        height,
        (y) => List.generate(
          width,
          (x) {
            final px = resized.getPixel(x, y);
            return [
              px.r.toDouble(),
              px.g.toDouble(),
              px.b.toDouble(),
            ];
          },
        ),
      ),
    );

    final classes = outputTensor.shape.last;
    if (classes != _labels.length) {
      throw LocalInferenceUnavailable(
        'Modellausgabe ($classes Klassen) passt nicht zur '
        'Labeldatei (${_labels.length}).',
      );
    }
    final output = [List<double>.filled(classes, 0)];
    interpreter.run(input, output);

    final scored = <({int index, double score})>[
      for (var i = 0; i < output.first.length; i++)
        (index: i, score: output.first[i]),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(3).map((item) {
      final score = item.score.clamp(0.0, 1.0);
      return ScanPrediction(
        name: _labels[item.index],
        visualFit: (score * 100).round(),
        reason:
            'On-Device-TFLite-Inferenz aus dem lokal geprueften Modellpaket.',
        category: 'Offline-Modell',
      );
    }).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
