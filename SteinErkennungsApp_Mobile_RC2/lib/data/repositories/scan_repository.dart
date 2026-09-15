import 'dart:convert';
import 'dart:io';

import '../../core/result.dart';
import '../../domain/models.dart';
import '../../services/image_preprocessor.dart';
import '../../services/local_inference_service.dart';
import '../remote/api_client.dart';

class ScanRepository {
  ScanRepository({
    required ApiClient api,
    required LocalInferenceService localInference,
    required ImagePreprocessor preprocessor,
  })  : _api = api,
        _localInference = localInference,
        _preprocessor = preprocessor;

  final ApiClient _api;
  final LocalInferenceService _localInference;
  final ImagePreprocessor _preprocessor;

  Future<AppResult<ScanResult>> identify({
    required List<File> images,
    required List<String> perspectives,
    String? reducedLocation,
    bool preferOffline = true,
  }) async {
    if (images.length < 2) {
      return const AppFailure('Mindestens zwei Perspektiven sind erforderlich.');
    }

    if (preferOffline) {
      try {
        final perImage = <List<ScanPrediction>>[];
        for (final image in images) {
          perImage.add(await _localInference.classify(image));
        }
        final aggregated = _aggregate(perImage);
        return AppSuccess(ScanResult(
          candidates: aggregated,
          comparisons: const [],
          observations: const [
            'Offline-Ergebnis aus mehreren Perspektiven aggregiert.'
          ],
          uncertainty:
              'Offline-Modellresultat. Standortkontext ist in diesem Modus getrennt.',
          needsMoreInfo: const [],
          region: RegionContext.empty,
          source: 'local_tflite',
        ));
      } on LocalInferenceUnavailable {
        // Sauber auf Remote wechseln; keine Fake-Erkennung.
      } catch (_) {
        // Lokaler Inferenzfehler darf den Online-Fallback nicht verhindern.
      }
    }

    try {
      final prepared = <PreparedImage>[];
      for (final image in images) {
        prepared.add(await _preprocessor.prepare(image));
      }
      final body = {
        'images': [
          for (final item in prepared)
            {
              'data': base64Encode(item.bytes),
              'mimeType': 'image/jpeg',
            }
        ],
        'perspectives': perspectives.take(prepared.length).toList(),
        if (reducedLocation != null) 'location': reducedLocation,
      };
      final json = await _api.postJson('/api/identify', body);
      return AppSuccess(ScanResult.fromJson(json, source: 'remote_ai'));
    } catch (e) {
      return AppFailure(
        'Weder lokales Modell noch Online-Erkennung waren verfuegbar.',
        e,
      );
    }
  }

  List<ScanPrediction> _aggregate(List<List<ScanPrediction>> sets) {
    final sums = <String, double>{};
    final reasons = <String, List<String>>{};
    for (final set in sets) {
      for (final item in set) {
        sums.update(
          item.name,
          (v) => v + item.visualFit,
          ifAbsent: () => item.visualFit.toDouble(),
        );
        reasons.putIfAbsent(item.name, () => []).add(item.reason);
      }
    }
    final result = sums.entries
        .map((e) => ScanPrediction(
              name: e.key,
              visualFit: (e.value / sets.length).round().clamp(0, 100).toInt(),
              reason: 'Mehrbild-Mittelwert aus ${sets.length} Perspektiven.',
              category: 'Offline-Modell',
            ))
        .toList()
      ..sort((a, b) => b.visualFit.compareTo(a.visualFit));
    return result.take(3).toList();
  }
}
