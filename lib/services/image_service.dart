import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImageService instance = ImageService._internal();
  ImageService._internal();

  static const String cdnBaseUrl =
      'https://cdn.jsdelivr.net/gh/codecompiler19-sketch/SnapBlockTales@main/assets/images/levels';

  final Map<String, ui.Image> _cache = {};

  /// Translates a local asset path (e.g. assets/images/levels/level_1.webp)
  /// into its cloud CDN URL if it's a level image.
  String resolveCloudUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final regex = RegExp(r'level_(\d+)\.(webp|png)');
    final match = regex.firstMatch(path);
    if (match != null) {
      final id = match.group(1);
      return '$cdnBaseUrl/level_$id.webp';
    }
    return path;
  }

  /// Returns the local cached File path for a given remote URL on mobile/desktop.
  Future<File?> _getLocalCacheFile(String url) async {
    if (kIsWeb) return null;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/snapblocktales_cache');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }
      final fileName = url.split('/').last.split('?').first;
      return File('${cacheDir.path}/$fileName');
    } catch (_) {
      return null;
    }
  }

  /// Loads and decodes a [ui.Image] from cache, local file, asset bundle, or CDN.
  Future<ui.Image> loadImage(String imagePath, {bool isFile = false}) async {
    if (_cache.containsKey(imagePath)) {
      return _cache[imagePath]!;
    }

    final Completer<ui.Image> completer = Completer<ui.Image>();
    Uint8List? bytes;

    if (isFile) {
      final xFile = XFile(imagePath);
      bytes = await xFile.readAsBytes();
    } else {
      // 1. Try local disk cache if it's a cloud-enabled level image
      final cloudUrl = resolveCloudUrl(imagePath);
      final isCloud = cloudUrl.startsWith('http://') || cloudUrl.startsWith('https://');

      if (isCloud && !kIsWeb) {
        final cacheFile = await _getLocalCacheFile(cloudUrl);
        if (cacheFile != null && cacheFile.existsSync()) {
          bytes = await cacheFile.readAsBytes();
        }
      }

      // 2. If not in disk cache, check if bundled locally in app assets
      if (bytes == null && !isCloud) {
        try {
          final data = await rootBundle.load(imagePath);
          bytes = data.buffer.asUint8List();
        } catch (_) {
          // Not bundled locally, fall through to download from cloud
        }
      }

      // 3. Download from CDN if not bundled or not yet cached
      if (bytes == null && isCloud) {
        try {
          final resp = await http.get(Uri.parse(cloudUrl));
          if (resp.statusCode == 200) {
            bytes = resp.bodyBytes;
            // Save to local disk cache for permanent offline use
            if (!kIsWeb) {
              final cacheFile = await _getLocalCacheFile(cloudUrl);
              if (cacheFile != null) {
                await cacheFile.writeAsBytes(bytes);
              }
            }
          }
        } catch (_) {
          // If network failed, check if bundled as fallback
          try {
            final data = await rootBundle.load(imagePath);
            bytes = data.buffer.asUint8List();
          } catch (_) {}
        }
      }

      // Final fallback to bundle
      if (bytes == null) {
        final data = await rootBundle.load(imagePath);
        bytes = data.buffer.asUint8List();
      }
    }

    ui.decodeImageFromList(bytes, (ui.Image img) {
      _cache[imagePath] = img;
      completer.complete(img);
    });

    return completer.future;
  }

  /// Builds a responsive, cached widget for displaying level artwork.
  Widget buildLevelImage(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    final cloudUrl = resolveCloudUrl(imagePath);
    final isCloud = cloudUrl.startsWith('http://') || cloudUrl.startsWith('https://');

    if (!isCloud) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
      );
    }

    return Image.network(
      cloudUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF1E2235),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Fallback to asset if network temporarily unavailable
        return Image.asset(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: const Color(0xFF141724),
            child: const Icon(Icons.image_outlined, color: Colors.white24),
          ),
        );
      },
    );
  }

  void clearCache() {
    for (final img in _cache.values) {
      img.dispose();
    }
    _cache.clear();
  }
}
