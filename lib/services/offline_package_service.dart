import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/local/app_database.dart';
import '../data/remote/api_client.dart';

class OfflinePackageService {
  OfflinePackageService(this._api, this._db);
  final ApiClient _api;
  final AppDatabase _db;

  Future<String> installCore() async {
    final payload = await _api.getJson('/api/offline/package');
    return _install(payload);
  }

  Future<String> installRegion() async {
    final payload = await _api.getJson('/api/offline/region');
    return _install(payload);
  }

  Future<String> _install(Map<String, dynamic> payload) async {
    final packageId = (payload['packageId'] ?? '').toString();
    final version = (payload['version'] ?? '').toString();
    if (packageId.isEmpty || version.isEmpty) {
      throw const FormatException('Offline-Paket ohne ID/Version.');
    }
    final encoded = jsonEncode(payload);
    final checksum = sha256.convert(utf8.encode(encoded)).toString();
    await _db.upsertPackage(
      packageId: packageId,
      version: version,
      checksum: checksum,
      payload: encoded,
    );
    return '$packageId $version';
  }
}
