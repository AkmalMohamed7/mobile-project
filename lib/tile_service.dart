import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

class TileService {
  static String? _tilesPath;

  static Future<String> getTilesPath() async {
    if (_tilesPath != null) return _tilesPath!;

    final appDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory('${appDir.path}/tiles');

    if (!tilesDir.existsSync()) {
      tilesDir.createSync(recursive: true);

      // Read the zip from assets
      final byteData = await rootBundle.load('assets/tiles_map.zip');
      final bytes = byteData.buffer.asUint8List();

      // Extract
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile) {
          final filePath = '${appDir.path}/tiles/${file.name}';
          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        }
      }
    }

    _tilesPath = tilesDir.path;
    return _tilesPath!;
  }
}
