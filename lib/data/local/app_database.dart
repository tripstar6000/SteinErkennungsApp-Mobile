import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../services/scan_image_store.dart';

class AppDatabase {
  AppDatabase({ScanImageStore? imageStore})
      : _imageStore = imageStore ?? ScanImageStore();

  final ScanImageStore _imageStore;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open().catchError((Object error) {
    _opening = null;
    throw error;
  });

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'steinerkennungsapp.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE scans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            top_candidate TEXT NOT NULL,
            visual_fit INTEGER,
            image_paths TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            region_code TEXT,
            raw_result TEXT NOT NULL,
            favorite INTEGER NOT NULL DEFAULT 0,
            note TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE packages(
            package_id TEXT PRIMARY KEY,
            version TEXT NOT NULL,
            checksum TEXT,
            payload TEXT NOT NULL,
            installed_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> saveScan({
    required String topCandidate,
    required int visualFit,
    required List<String> imagePaths,
    required Map<String, dynamic> rawResult,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    return db.insert('scans', {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'top_candidate': topCandidate,
      'visual_fit': visualFit,
      'image_paths': jsonEncode(imagePaths),
      'latitude': latitude,
      'longitude': longitude,
      'raw_result': jsonEncode(rawResult),
    });
  }

  Future<List<Map<String, Object?>>> scans() async {
    final db = await database;
    return db.query('scans', orderBy: 'timestamp DESC', limit: 200);
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setFavorite(int id, bool value) async {
    final db = await database;
    await db.update(
      'scans',
      {'favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertPackage({
    required String packageId,
    required String version,
    required String payload,
    String? checksum,
  }) async {
    final db = await database;
    await db.insert(
      'packages',
      {
        'package_id': packageId,
        'version': version,
        'checksum': checksum,
        'payload': payload,
        'installed_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> package(String id) async {
    final db = await database;
    final rows = await db.query(
      'packages',
      where: 'package_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
}
