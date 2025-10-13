import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  Future<Uint8List> captureImage(GlobalKey repaintKey) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as ui.RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('No render boundary found for story card');
    }
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode story card image');
    }
    return byteData.buffer.asUint8List();
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
  }) async {
    final directory = await _resolveStoryDirectory();
    final fileName = _buildFileName(data);
    final file = File(p.join(directory.path, fileName));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _resolveStoryDirectory() async {
    if (kIsWeb) {
      return Directory.systemTemp.createTemp('tapem-story');
    }
    if (Platform.isAndroid) {
      final directories = await getExternalStorageDirectories(type: StorageDirectory.pictures);
      final base = directories?.isNotEmpty == true
          ? directories!.first
          : await getExternalStorageDirectory();
      if (base == null) {
        return await getTemporaryDirectory();
      }
      final dir = Directory(p.join(base.path, 'Tapem', 'Stories'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'Tapem', 'Stories'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final temp = await getTemporaryDirectory();
    final dir = Directory(p.join(temp.path, 'Tapem', 'Stories'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _buildFileName(SessionStoryData data) {
    final dateKey = DateFormat('yyyyMMdd').format(data.occurredAt.toLocal());
    return '${dateKey}_${data.sessionId}.png';
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
