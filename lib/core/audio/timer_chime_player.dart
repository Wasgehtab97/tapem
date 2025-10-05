import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

const _kPluginVersion = '5.2.1';
const _kDefaultAsset = 'audio/session_timer_end.wav';
const _kAlternateAsset = 'audio/session_timer_end.mp3';

void _logAudio({
  required String name,
  AppLogLevel level = AppLogLevel.info,
  String? timerId,
  Map<String, Object?> details = const {},
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kAudioVerboseLogs && level == AppLogLevel.info) {
    return;
  }
  logAppEvent(
    category: AppLogCategory.audio,
    name: name,
    level: level,
    timerId: timerId,
    details: details,
    error: error,
    stackTrace: stackTrace,
  );
}

class TimerChimePlayer {
  TimerChimePlayer({
    AudioPlayer? player,
    String assetPath = _kDefaultAsset,
  })  : _player = player ?? AudioPlayer(playerId: 'timer_sound'),
        _assetPathRaw = assetPath,
        _assetPath = _sanitizeAssetPath(assetPath) {
    _attachListeners();
  }

  final AudioPlayer _player;
  final String _assetPathRaw;
  final String _assetPath;

  bool _initInProgress = false;
  bool _ready = false;
  bool _listenersAttached = false;
  bool _assetValidated = false;
  bool _assetFound = false;
  bool _alternateAssetFound = false;
  bool _usingAlternate = false;
  bool _durationWatchdogArmed = false;
  bool _fallbackScheduled = false;

  Duration? _duration;
  PlayerState _lastState = PlayerState.stopped;
  Duration _lastPositionLog = Duration.zero;

  String? _activeTimerId;
  Completer<void>? _playbackCompleter;

  final ValueNotifier<PlayerState> _stateNotifier =
      ValueNotifier<PlayerState>(PlayerState.stopped);
  final ValueNotifier<Duration?> _durationNotifier =
      ValueNotifier<Duration?>(null);
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier<Duration>(Duration.zero);

  ValueNotifier<PlayerState> get stateNotifier => _stateNotifier;
  ValueNotifier<Duration?> get durationNotifier => _durationNotifier;
  ValueNotifier<Duration> get positionNotifier => _positionNotifier;

  String get currentAssetKey => _usingAlternate ? _kAlternateAsset : _assetPath;

  static String _sanitizeAssetPath(String path) {
    var sanitized = path.trim();
    if (sanitized.startsWith('/')) {
      sanitized = sanitized.substring(1);
    }
    if (sanitized.startsWith('assets/')) {
      sanitized = sanitized.substring('assets/'.length);
    }
    return sanitized;
  }

  Future<void> configureForTimer({required String timerId}) async {
    _activeTimerId = timerId;
    if (_assetPathRaw != _assetPath) {
      _logAudio(
        name: 'ASSET_SANITIZED',
        timerId: timerId,
        details: {
          'raw': _assetPathRaw,
          'sanitized': _assetPath,
        },
      );
    }

    await _validateAsset(timerId: timerId);
    await _init(timerId: timerId);
  }

  Future<void> _validateAsset({required String timerId}) async {
    if (_assetValidated) {
      _logAudio(
        name: 'ASSET_VALIDATED',
        timerId: timerId,
        details: {
          'found': _assetFound,
          'alternateFound': _alternateAssetFound,
          'assetKey': _assetPath,
          'pubspecPath': _pubspecAssetPath(),
        },
      );
      return;
    }

    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> data = json.decode(manifest);
      final pubspecPath = _pubspecAssetPath();
      _assetFound = data.containsKey(pubspecPath);
      final altPath = _alternatePubspecPath(pubspecPath);
      _alternateAssetFound = data.containsKey(altPath);
      _assetValidated = true;
      _logAudio(
        name: 'ASSET_VALIDATED',
        timerId: timerId,
        details: {
          'found': _assetFound,
          'alternateFound': _alternateAssetFound,
          'assetKey': _assetPath,
          'pubspecPath': pubspecPath,
        },
      );
      if (!_assetFound) {
        _logAudio(
          name: 'AUDIO_INIT_FAIL',
          level: AppLogLevel.error,
          timerId: timerId,
          details: {
            'reason': 'asset_missing',
            'pubspecPath': pubspecPath,
            'hint': 'Add assets/audio/session_timer_end.wav to pubspec.yaml and bundle it.',
          },
        );
      }
    } on Object catch (e, st) {
      _logAudio(
        name: 'ASSET_VALIDATION_ERROR',
        level: AppLogLevel.error,
        timerId: timerId,
        details: {
          'assetKey': _assetPath,
        },
        error: e,
        stackTrace: st,
      );
    }
  }

  String _pubspecAssetPath() {
    return _assetPathRaw.startsWith('assets/')
        ? _assetPathRaw
        : 'assets/$_assetPath';
  }

  String _alternatePubspecPath(String pubspecPath) {
    if (pubspecPath.endsWith('.wav')) {
      return pubspecPath.substring(0, pubspecPath.length - 4) + '.mp3';
    }
    return pubspecPath;
  }

  Future<void> _init({required String timerId}) async {
    if (_ready || _initInProgress) {
      while (_initInProgress) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return;
    }
    _initInProgress = true;
    _logAudio(
      name: 'AUDIO_INIT_START',
      timerId: timerId,
      details: {
        'assetPathRaw': _assetPathRaw,
        'assetKey': _assetPath,
        'pubspecPath': _pubspecAssetPath(),
      },
    );
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      await _setSource(
        assetKey: currentAssetKey,
        timerId: timerId,
        reason: 'preload',
      );
      _ready = true;
      _armDurationWatchdog(timerId: timerId);
      _logAudio(
        name: 'AUDIO_INIT_OK',
        timerId: timerId,
        details: {
          'pluginVersion': _kPluginVersion,
          'platform': defaultTargetPlatform.name,
          'assetKey': currentAssetKey,
        },
      );
    } on Object catch (e, st) {
      _ready = false;
      _logAudio(
        name: 'AUDIO_INIT_FAIL',
        level: AppLogLevel.error,
        timerId: timerId,
        details: {
          'assetKey': currentAssetKey,
        },
        error: e,
        stackTrace: st,
      );
    } finally {
      _initInProgress = false;
    }
  }

  Future<void> _setSource({
    required String assetKey,
    required String timerId,
    required String reason,
  }) async {
    await _player.setSource(AssetSource(assetKey));
    _logAudio(
      name: 'AUDIO_PRELOAD',
      timerId: timerId,
      details: {
        'assetKey': assetKey,
        'reason': reason,
      },
    );
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _player.onPlayerStateChanged.listen((state) {
      _lastState = state;
      _stateNotifier.value = state;
      final timerId = _activeTimerId;
      if (timerId != null) {
        _logAudio(
          name: 'AUDIO_STATE',
          timerId: timerId,
          details: {
            'state': state.name,
          },
        );
      }
    });

    _player.onDurationChanged.listen((duration) {
      _duration = duration;
      _durationNotifier.value = duration;
      final timerId = _activeTimerId;
      if (timerId != null) {
        _logAudio(
          name: 'AUDIO_DURATION',
          timerId: timerId,
          details: {
            'seconds': duration.inMilliseconds / 1000,
          },
        );
      }
    });

    _player.onPositionChanged.listen((position) {
      _positionNotifier.value = position;
      final timerId = _activeTimerId;
      if (timerId == null) {
        return;
      }
      if ((position - _lastPositionLog).abs() >=
          const Duration(milliseconds: 500)) {
        _lastPositionLog = position;
        _logAudio(
          name: 'AUDIO_POSITION',
          timerId: timerId,
          details: {
            'millis': position.inMilliseconds,
          },
        );
      }
    });

    _player.onPlayerComplete.listen((event) {
      _playbackCompleter?.complete();
      final timerId = _activeTimerId;
      if (timerId != null) {
        _logAudio(
          name: 'AUDIO_COMPLETE',
          timerId: timerId,
          details: {
            'assetKey': currentAssetKey,
          },
        );
      }
    });
  }

  void _armDurationWatchdog({required String timerId}) {
    if (_durationWatchdogArmed) return;
    _durationWatchdogArmed = true;
    Future<void>.delayed(const Duration(seconds: 2)).then((_) async {
      if (_duration != null) {
        return;
      }
      _logAudio(
        name: 'AUDIO_NO_DURATION',
        level: AppLogLevel.warning,
        timerId: timerId,
        details: {
          'assetKey': currentAssetKey,
        },
      );
      if (_alternateAssetFound && !_usingAlternate) {
        _usingAlternate = true;
        _logAudio(
          name: 'AUDIO_FALLBACK',
          level: AppLogLevel.warning,
          timerId: timerId,
          details: {
            'strategy': 'codec_switch',
            'codec': 'mp3',
          },
        );
        try {
          await _setSource(
            assetKey: _kAlternateAsset,
            timerId: timerId,
            reason: 'fallback_mp3',
          );
        } on Object catch (e, st) {
          _logAudio(
            name: 'AUDIO_PLAY_FAIL',
            level: AppLogLevel.error,
            timerId: timerId,
            details: {
              'strategy': 'codec_switch',
            },
            error: e,
            stackTrace: st,
          );
        }
      }
    });
  }

  Future<void> play({required String timerId}) async {
    _activeTimerId = timerId;
    await configureForTimer(timerId: timerId);
    if (!_ready) {
      _logAudio(
        name: 'AUDIO_PLAY_FAIL',
        level: AppLogLevel.error,
        timerId: timerId,
        details: {
          'reason': 'not_ready',
        },
      );
      return;
    }

    _fallbackScheduled = false;
    _playbackCompleter = Completer<void>();
    try {
      _logAudio(
        name: 'AUDIO_PLAY_ATTEMPT',
        timerId: timerId,
        details: {
          'strategy': 'seekResume',
          'assetKey': currentAssetKey,
        },
      );
      await _player.seek(Duration.zero);
      await _player.resume();
      _scheduleFallbackCheck(timerId: timerId);
    } on Object catch (e, st) {
      _logAudio(
        name: 'AUDIO_PLAY_FAIL',
        level: AppLogLevel.error,
        timerId: timerId,
        details: {
          'strategy': 'seekResume',
        },
        error: e,
        stackTrace: st,
      );
    }
  }

  void _scheduleFallbackCheck({required String timerId}) {
    Future<void>.delayed(const Duration(milliseconds: 300)).then((_) async {
      if (_fallbackScheduled || _playbackCompleter == null) {
        return;
      }
      if (_lastState == PlayerState.playing) {
        return;
      }
      _fallbackScheduled = true;
      _logAudio(
        name: 'AUDIO_FALLBACK',
        level: AppLogLevel.warning,
        timerId: timerId,
        details: {
          'strategy': 'playAsset',
          'state': _lastState.name,
        },
      );
      try {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await _player.play(AssetSource(currentAssetKey));
      } on Object catch (e, st) {
        _logAudio(
          name: 'AUDIO_PLAY_FAIL',
          level: AppLogLevel.error,
          timerId: timerId,
          details: {
            'strategy': 'playAsset',
          },
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<bool> waitForCompletion({
    required String timerId,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    _activeTimerId = timerId;
    final completer = _playbackCompleter;
    if (completer == null) {
      return true;
    }
    try {
      await completer.future.timeout(timeout);
      return true;
    } on TimeoutException {
      _logAudio(
        name: 'AUDIO_COMPLETE_TIMEOUT',
        level: AppLogLevel.warning,
        timerId: timerId,
        details: {
          'timeoutMs': timeout.inMilliseconds,
        },
      );
      return false;
    }
  }

  static Future<void> configureGlobalAudioContext() async {
    try {
      await AudioPlayer.global.setAudioContext(
        const AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            ],
          ),
          android: AudioContextAndroid(
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.music,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      _logAudio(
        name: 'AUDIO_CTX_SET',
        details: {
          'platform': defaultTargetPlatform.name,
          'iosCategory': 'playback',
          'iosOptions': 'mixWithOthers,defaultToSpeaker',
          'androidUsage': 'media',
          'androidContentType': 'music',
          'androidFocus': 'gainTransientMayDuck',
        },
      );
    } on Object catch (e, st) {
      _logAudio(
        name: 'AUDIO_CTX_SET',
        level: AppLogLevel.error,
        details: {
          'platform': defaultTargetPlatform.name,
        },
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } on Object catch (e, st) {
      _logAudio(
        name: 'AUDIO_DISPOSE_FAIL',
        level: AppLogLevel.error,
        details: const {
          'component': 'TimerChimePlayer',
        },
        error: e,
        stackTrace: st,
      );
    }
  }
}
