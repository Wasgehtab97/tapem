import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'domain/session_story_data.dart';

class SessionStoryShareResult {
  final bool shared;
  final String filePath;
  final String? target;

  const SessionStoryShareResult({
    required this.shared,
    required this.filePath,
    this.target,
  });
}

class SessionStoryShareService {
  static const int _maxImageBytes = 6 * 1024 * 1024; // 6 MiB safety cap

  Future<Uint8List> captureImage(GlobalKey repaintKey) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('No render boundary found for story card');
    }
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    var pixelRatio = _resolvePixelRatio(boundary);
    var bytes = await _renderBoundary(boundary, pixelRatio);
    if (bytes.lengthInBytes > _maxImageBytes) {
      pixelRatio = math.max(1.5, pixelRatio * 0.75);
      bytes = await _renderBoundary(boundary, pixelRatio);
    }
    if (bytes.lengthInBytes > _maxImageBytes) {
      pixelRatio = math.max(1.25, pixelRatio * 0.7);
      bytes = await _renderBoundary(boundary, pixelRatio);
    }
    return bytes;
  }

  Future<String> saveImage({
    required GlobalKey repaintKey,
    required SessionStoryData data,
  }) async {
    final bytes = await captureImage(repaintKey);
    return _persistImage(bytes: bytes, data: data);
  }

  Future<SessionStoryShareResult> shareImage({
    required BuildContext context,
    required GlobalKey repaintKey,
    required SessionStoryData data,
    Uri? deepLink,
  }) async {
    final bytes = await captureImage(repaintKey);
    final path = await _persistImage(bytes: bytes, data: data);

    if (kIsWeb) {
      return SessionStoryShareResult(shared: false, filePath: path);
    }

    final xFile = XFile(path, mimeType: 'image/png');
    final message = deepLink?.toString();
    final result = await Share.shareXFiles([xFile], text: message);
    final target = _resolveShareTarget(result);
    final shared = result.status == ShareResultStatus.success;
    return SessionStoryShareResult(shared: shared, filePath: path, target: target);
  }

  Future<String> _persistImage({
    required Uint8List bytes,
    required SessionStoryData data,
    List<Directory>? overrideDirectories,
  }) async {
    final candidates = overrideDirectories ?? await _resolveStoryDirectories();
    final fileName = _buildFileName(data);
    final errors = <Object>[];
    for (final directory in candidates) {
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File(p.join(directory.path, fileName));
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (error, stack) {
        debugPrint('SessionStoryShareService._persistImage error: $error\n$stack');
        errors.add(error);
      }
    }
    final message = errors.isNotEmpty ? errors.last.toString() : 'unknown';
    throw FileSystemException('Unable to persist story image', message);
  }

  Future<List<Directory>> _resolveStoryDirectories() async {
    if (kIsWeb) {
      final temp = await Directory.systemTemp.createTemp('tapem-story');
      return [temp];
    }

    final directories = <Directory>[];
    final preferred = await _resolvePreferredDirectory();
    if (preferred != null) {
      directories.add(preferred);
    }

    final temp = await getTemporaryDirectory();
    if (!directories.any((dir) => dir.path == temp.path)) {
      directories.add(temp);
    }
    return directories;
  }

  Future<Directory?> _resolvePreferredDirectory() async {
    try {
      if (Platform.isAndroid) {
        final directories = await getExternalStorageDirectories(type: StorageDirectory.pictures);
        final base = directories?.isNotEmpty == true ? directories!.first : await getExternalStorageDirectory();
        if (base == null) {
          return null;
        }
        return Directory(p.join(base.path, 'Tapem', 'Stories'));
      }
      if (Platform.isIOS) {
        final docs = await getApplicationDocumentsDirectory();
        return Directory(p.join(docs.path, 'Tapem', 'Stories'));
      }
      final temp = await getTemporaryDirectory();
      return Directory(p.join(temp.path, 'Tapem', 'Stories'));
    } catch (error, stack) {
      debugPrint('SessionStoryShareService._resolvePreferredDirectory error: $error\n$stack');
      return null;
    }
  }

  Future<Uint8List> _renderBoundary(RenderRepaintBoundary boundary, double pixelRatio) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode story card image');
    }
    return byteData.buffer.asUint8List();
  }

  double _resolvePixelRatio(RenderRepaintBoundary boundary, {double targetMegaPixels = 5}) {
    return _resolvePixelRatioForSize(boundary.size, targetMegaPixels: targetMegaPixels);
  }

  @visibleForTesting
  double debugResolvePixelRatioForSize(ui.Size size, {double targetMegaPixels = 5}) {
    return _resolvePixelRatioForSize(size, targetMegaPixels: targetMegaPixels);
  }

  double _resolvePixelRatioForSize(ui.Size size, {double targetMegaPixels = 5}) {
    const double defaultRatio = 3.0;
    if (size.isEmpty) {
      return defaultRatio;
    }
    final pixelCount = size.width * size.height;
    if (pixelCount <= 0) {
      return defaultRatio;
    }
    final maxPixels = targetMegaPixels * 1000000;
    final estimated = pixelCount * defaultRatio * defaultRatio;
    if (estimated <= maxPixels) {
      return defaultRatio;
    }
    final ratio = math.sqrt(maxPixels / pixelCount);
    return ratio.clamp(1.5, defaultRatio);
  }

  String _buildFileName(SessionStoryData data) {
    final dateKey = DateFormat('yyyyMMdd').format(data.occurredAt.toLocal());
    return '${dateKey}_${data.sessionId}.png';
  }

  @visibleForTesting
  Future<String> debugPersistImage({
    required Uint8List bytes,
    required SessionStoryData data,
    required List<Directory> directories,
  }) {
    return _persistImage(bytes: bytes, data: data, overrideDirectories: directories);
  }

  String? _resolveShareTarget(ShareResult result) {
    final raw = result.raw;
    if (raw == null) {
      return null;
    }
    final normalized = raw.toLowerCase();
    if (normalized.contains('whats')) return 'whatsapp';
    if (normalized.contains('instagram')) return 'instagram';
    if (normalized.contains('facebook')) return 'facebook';
    if (normalized.contains('messages')) return 'messages';
    return normalized;
  }
}
