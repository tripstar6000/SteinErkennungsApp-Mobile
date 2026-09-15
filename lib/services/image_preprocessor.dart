import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../core/app_config.dart';

class PreparedImage {
  const PreparedImage(this.file, this.bytes);
  final File file;
  final Uint8List bytes;
}

class ImagePreprocessor {
  Future<PreparedImage> prepare(File source) async {
    final raw = await source.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw const FormatException('Bild konnte nicht dekodiert werden.');
    }
    final oriented = img.bakeOrientation(decoded);
    final longest = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final resized = longest > AppConfig.maxImageDimension
        ? (oriented.width >= oriented.height
            ? img.copyResize(
                oriented,
                width: AppConfig.maxImageDimension,
                interpolation: img.Interpolation.average,
              )
            : img.copyResize(
                oriented,
                height: AppConfig.maxImageDimension,
                interpolation: img.Interpolation.average,
              ))
        : oriented;
    final jpg = Uint8List.fromList(img.encodeJpg(resized, quality: 78));
    final dir = await getTemporaryDirectory();
    final output = File(
      '${dir.path}/scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await output.writeAsBytes(jpg, flush: true);
    return PreparedImage(output, jpg);
  }
}
