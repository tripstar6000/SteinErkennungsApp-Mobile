import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/remote/api_client.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/scan_repository.dart';
import 'image_preprocessor.dart';
import 'local_inference_service.dart';
import 'location_service.dart';
import 'model_manager.dart';
import 'offline_package_service.dart';
import 'physical_refiner.dart';

final databaseProvider = Provider((ref) => AppDatabase());
final apiProvider = Provider((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});
final catalogProvider = Provider((ref) => CatalogRepository());
final modelManagerProvider = Provider((ref) => ModelManager());
final locationServiceProvider = Provider((ref) => LocationService());
final imagePreprocessorProvider = Provider((ref) => ImagePreprocessor());
final physicalRefinerProvider = Provider((ref) => PhysicalRefiner());

final localInferenceProvider = Provider((ref) {
  final service = LocalInferenceService(ref.watch(modelManagerProvider));
  ref.onDispose(service.dispose);
  return service;
});

final scanRepositoryProvider = Provider((ref) => ScanRepository(
      api: ref.watch(apiProvider),
      localInference: ref.watch(localInferenceProvider),
      preprocessor: ref.watch(imagePreprocessorProvider),
    ));

final offlinePackageProvider = Provider((ref) => OfflinePackageService(
      ref.watch(apiProvider),
      ref.watch(databaseProvider),
    ));
