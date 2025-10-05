import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the audible cue that indicates a session timer has completed.
///
/// The player keeps a single [AudioPlayer] instance so we can warm the
/// underlying platform channel and minimise latency when the sound is needed.
class TimerSoundPlayer {
  TimerSoundPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _preloadAsset();
  }

  static const String _assetPath = 'assets/audio/session_timer_end.wav';

  final AudioPlayer _player;
  bool _hasValidSource = false;
  bool _isPreloading = false;

  /// Attempts to preload the asset so the first playback is instant.
  Future<void> _preloadAsset() async {
    if (_isPreloading) {
      return;
    }
    _isPreloading = true;
    try {
      await _player.setSourceAsset(_assetPath);
      _hasValidSource = true;
    } on Object catch (error, stackTrace) {
      _hasValidSource = false;
      log(
        'Unable to prepare the session timer audio asset. '
        'Verify that the file exists at $_assetPath and is declared in pubspec.yaml.',
        error: error,
        stackTrace: stackTrace,
        name: 'TimerSoundPlayer',
      );
    } finally {
      _isPreloading = false;
    }
  }

  /// Plays the end-of-timer chime if the audio asset is available.
  Future<void> play() async {
    if (!_hasValidSource) {
      await _preloadAsset();
    }

    if (!_hasValidSource) {
      if (kDebugMode) {
        log(
          'Skipping session timer audio playback because the asset '
          'is unavailable. Ensure the file exists at $_assetPath.',
          name: 'TimerSoundPlayer',
        );
      }
      return;
    }

    try {
      await _player.stop();
      await _player.resume();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to play the session timer audio cue.',
        error: error,
        stackTrace: stackTrace,
        name: 'TimerSoundPlayer',
      );
    }
  }
}
