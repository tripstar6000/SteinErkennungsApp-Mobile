import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_config.dart';

class ModelManifest {
  const ModelManifest({
    required this.modelSha256,
    required this.labelsSha256,
    required this.inputType,
    required this.normalization,
    required this.classCount,
    required this.dataset,
    required this.datasetLicense,
  });

  final String modelSha256;
  final String labelsSha256;
  final String inputType;
  final String normalization;
  final int classCount;
  final String dataset;
  final String datasetLicense;

  factory ModelManifest.fromJson(Map<String, dynamic> json) => ModelManifest(
        modelSha256: (json['model_sha256'] ?? '').toString().toLowerCase(),
        labelsSha256: (json['labels_sha256'] ?? '').toString().toLowerCase(),
        inputType: (json['input_type'] ?? '').toString(),
        normalization: (json['normalization'] ?? '').toString(),
        classCount: (json['class_count'] as num? ?? 0).toInt(),
        dataset: (json['dataset'] ?? '').toString(),
        datasetLicense: (json['dataset_license'] ?? '').toString(),
      );
}

class ModelManager {
  Future<Directory> _modelDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/models/${AppConfig.modelPackageId}');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> modelFile() async =>
      File('${(await _modelDir()).path}/${AppConfig.modelFileName}');

  Future<File> labelsFile() async =>
      File('${(await _modelDir()).path}/labels.txt');

  Future<File> manifestFile() async =>
      File('${(await _modelDir()).path}/model_manifest.json');

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureBundledModelInstalled() async {
    const bundledModel = 'assets/ml/stone_classifier.tflite';
    const bundledLabels = 'assets/ml/labels.txt';
    const bundledManifest = 'assets/ml/model_manifest.json';

    if (!await _assetExists(bundledModel) ||
        !await _assetExists(bundledLabels) ||
        !await _assetExists(bundledManifest)) {
      return;
    }

    final manifestRaw = await rootBundle.loadString(bundledManifest);
    final manifest = ModelManifest.fromJson(
      (jsonDecode(manifestRaw) as Map).cast<String, dynamic>(),
    );
    final modelBytes = (await rootBundle.load(bundledModel))
        .buffer
        .asUint8List();
    final labelsBytes = (await rootBundle.load(bundledLabels))
        .buffer
        .asUint8List();

    await install(
      modelBytes: modelBytes,
      labelsBytes: labelsBytes,
      manifestJson: manifestRaw,
      expectedModelSha256: manifest.modelSha256,
      expectedLabelsSha256: manifest.labelsSha256,
    );
  }

  Future<ModelManifest?> readManifest() async {
    final f = await manifestFile();
    if (!await f.exists()) return null;
    try {
      return ModelManifest.fromJson(
        (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> readLabels() async {
    final f = await labelsFile();
    if (!await f.exists()) return const [];
    return (await f.readAsLines())
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<bool> isInstalledAndValid() async {
    final model = await modelFile();
    final labels = await labelsFile();
    final manifest = await readManifest();
    if (!await model.exists() || !await labels.exists() || manifest == null) {
      return false;
    }
    final modelHash = sha256.convert(await model.readAsBytes()).toString();
    final labelsHash = sha256.convert(await labels.readAsBytes()).toString();
    if (modelHash != manifest.modelSha256 ||
        labelsHash != manifest.labelsSha256) {
      return false;
    }
    final labelLines = await readLabels();
    return manifest.classCount > 1 && labelLines.length == manifest.classCount;
  }

  Future<void> install({
    required List<int> modelBytes,
    required List<int> labelsBytes,
    required String manifestJson,
    required String expectedModelSha256,
    required String expectedLabelsSha256,
  }) async {
    final modelHash = sha256.convert(modelBytes).toString();
    final labelsHash = sha256.convert(labelsBytes).toString();
    if (modelHash.toLowerCase() != expectedModelSha256.toLowerCase()) {
      throw StateError('Modell-Checksumme stimmt nicht.');
    }
    if (labelsHash.toLowerCase() != expectedLabelsSha256.toLowerCase()) {
      throw StateError('Label-Checksumme stimmt nicht.');
    }
    await (await modelFile()).writeAsBytes(modelBytes, flush: true);
    await (await labelsFile()).writeAsBytes(labelsBytes, flush: true);
    await (await manifestFile()).writeAsString(manifestJson, flush: true);
  }

  Future<Map<String, dynamic>> status() async {
    await ensureBundledModelInstalled();
    final manifest = await readManifest();
    return {
      'packageId': AppConfig.modelPackageId,
      'installed': await isInstalledAndValid(),
      'modelPath': (await modelFile()).path,
      'classCount': manifest?.classCount ?? 0,
      'dataset': manifest?.dataset ?? '',
      'datasetLicense': manifest?.datasetLicense ?? '',
      'inputType': manifest?.inputType ?? '',
      'normalization': manifest?.normalization ?? '',
      'policy':
          'Nur SHA-256-gepruefte Modell- und Labelpakete werden geladen.',
    };
  }
}
