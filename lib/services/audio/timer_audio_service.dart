import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TimerAudioService {
  TimerAudioService({
    AudioPlayer? player,
    this.preAlertAssetPath = defaultAssetPath,
    this.endAssetPath = defaultAssetPath,
  })  : _player = player ??
            AudioPlayer(
              playerId: 'session_timer',
              mode: PlayerMode.lowLatency,
            ) {
    _ensureAudioContext();
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  static const String defaultAssetPath = 'assets/sounds/session_timer_end.wav';

  final AudioPlayer _player;
  final String preAlertAssetPath;
  final String endAssetPath;

  Uint8List? _preAlertBytes;
  Uint8List? _endBytes;
  bool _preloaded = false;
  bool _disposed = false;

  static bool _audioContextConfigured = false;

  static void _ensureAudioContext() {
    if (_audioContextConfigured) return;
    AudioPlayer.global.setAudioContext(
      const AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          usageType: AndroidUsageType.assistanceSonification,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
    _audioContextConfigured = true;
  }

  Future<void> preload() async {
    if (_preloaded) return;
    await Future.wait([
      _loadAsset(preAlertAssetPath, isPreAlert: true),
      if (endAssetPath != preAlertAssetPath)
        _loadAsset(endAssetPath, isPreAlert: false),
    ]);
    _preloaded = true;
  }

  Future<void> playPreAlert() => _play(preAlertAssetPath, isPreAlert: true);

  Future<void> playEnd() => _play(endAssetPath, isPreAlert: false);

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _player.stop();
    } catch (error, stackTrace) {
      debugPrint('TimerAudioService: stop failed: $error');
      debugPrint('$stackTrace');
    }
    await _player.dispose();
  }

  Future<void> _loadAsset(String assetPath, {required bool isPreAlert}) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      if (isPreAlert) {
        _preAlertBytes = bytes;
      } else {
        _endBytes = bytes;
      }
    } catch (error, stackTrace) {
      debugPrint('TimerAudioService: failed to load $assetPath: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _play(String assetPath, {required bool isPreAlert}) async {
    if (_disposed) return;
    try {
      await _player.stop();
      final bytes = isPreAlert ? _preAlertBytes : _endBytes;
      if (bytes != null) {
        await _player.setSource(BytesSource(bytes));
      } else {
        await _player.setSource(AssetSource(assetPath));
      }
      await _player.resume();
    } catch (error, stackTrace) {
      debugPrint('TimerAudioService: failed to play $assetPath: $error');
      debugPrint('$stackTrace');
    }
  }
}
