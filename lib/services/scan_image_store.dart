import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ScanImageStore {
  ScanImageStore({Future<Directory> Function()? baseDirectory})
      : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDirectory;

  Future<Directory> _root() async =>
      Directory(p.join((await _baseDirectory()).path, 'scan_photos'));

  Future<List<String>> copyForScan(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return [];
    final root = await _root();
    await root.create(recursive: true);
    final folder = await root.createTemp('scan_');
    try {
      final copies = <String>[];
      for (var i = 0; i < imagePaths.length; i++) {
        final source = File(imagePaths[i]);
        final extension = p.extension(source.path).toLowerCase();
        final destination = p.join(folder.path, 'photo_$i$extension');
        final copy = await source.copy(destination);
        copies.add(copy.path);
      }
      return copies;
    } catch (_) {
      await folder.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> deleteOwned(List<String> imagePaths) async {
    final root = await _root();
    if (!await root.exists()) return;
    final rootPath = await root.resolveSymbolicLinks();
    final folders = <String>{};
    for (final path in imagePaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final resolved = await file.resolveSymbolicLinks();
      if (!p.isWithin(rootPath, resolved)) continue;
      await file.delete();
      folders.add(p.dirname(resolved));
    }
    for (final path in folders) {
      final folder = Directory(path);
      if (path != rootPath && await folder.exists() && await folder.list().isEmpty) {
        await folder.delete();
      }
    }
  }
}
