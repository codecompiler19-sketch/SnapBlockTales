import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService instance = ImageService._internal();
  ImageService._internal();

  final Map<String, ui.Image> _cache = {};

  Future<ui.Image> loadImage(String imagePath, {bool isFile = false}) async {
    if (_cache.containsKey(imagePath)) {
      return _cache[imagePath]!;
    }

    final Completer<ui.Image> completer = Completer<ui.Image>();
    Uint8List bytes;

    if (isFile) {
      final xFile = XFile(imagePath);
      bytes = await xFile.readAsBytes();
    } else {
      final data = await rootBundle.load(imagePath);
      bytes = data.buffer.asUint8List();
    }

    ui.decodeImageFromList(bytes, (ui.Image img) {
      _cache[imagePath] = img;
      completer.complete(img);
    });

    return completer.future;
  }

  void clearCache() {
    for (final img in _cache.values) {
      img.dispose();
    }
    _cache.clear();
  }
}
