// lib/ui/timer/timer_sound_player.dart
// Kompatibel mit audioplayers ^5.x

import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

const _logTag = 'TimerSoundPlayer';

void _logInfo(String msg) => log(msg, name: _logTag);
void _logWarn(String msg) => log('WARN: $msg', name: _logTag);
void _logErr(String msg, [Object? error, StackTrace? st]) =>
    log('ERROR: $msg', name: _logTag, error: error, stackTrace: st);

/// Spielt den End-Of-Timer-Sound latenzarm und liefert umfangreiche Logs.
/// - Lädt das Asset einmalig vor (Preload) und hängt Debug-Listener an.
/// - Verhindert Klicks durch Verzicht auf unmittelbares stop()+setSource() vor play().
/// - Sanitiert fehlerhafte Asset-Pfade (kein führendes "/" / kein "assets/" im Key).
class TimerSoundPlayer {
  TimerSoundPlayer({
    AudioPlayer? player,
    String assetPath = 'audio/session_timer_end.wav',
    bool verboseLogging = true,
  }) : _verbose = verboseLogging,
       _assetPathRaw = assetPath,
       _assetPath = _sanitizeAssetPath(assetPath),
       _player = player ?? AudioPlayer(playerId: 'timer_sound') {
    _attachListeners();
    _initFuture = _init();
  }

  // -----------------
  // Felder / State
  // -----------------
  final AudioPlayer _player;
  final bool _verbose;

  final String _assetPathRaw; // was der Aufrufer übergeben hat
  final String
  _assetPath; // sanitisierte Variante (ohne führendes "/" / "assets/")

  bool _ready = false;
  bool _listenersAttached = false;
  Duration? _duration;
  Duration _lastPosLog = Duration.zero;

  StreamSubscription? _stateSub, _durSub, _posSub, _completeSub;

  Future<void>? _initFuture;

  // -----------------
  // Initialisierung
  // -----------------
  static String _sanitizeAssetPath(String p) {
    var s = p.trim();
    var changed = false;
    if (s.startsWith('/')) {
      s = s.substring(1);
      changed = true;
    }
    if (s.startsWith('assets/')) {
      s = s.substring('assets/'.length);
      changed = true;
    }
    if (changed) {
      _logWarn(
        'assetPath saniert: "$p" → "$s". Hinweis: Im Code KEIN führendes "/" und KEIN "assets/".',
      );
    }
    return s;
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (_verbose) _logInfo('state: $s');
    });

    _durSub = _player.onDurationChanged.listen((d) {
      _duration = d;
      if (_verbose) _logInfo('duration: $d (assetKey="$_assetPath")');
    });

    _posSub = _player.onPositionChanged.listen((p) {
      // drosseln: nur alle ~500ms loggen
      if (!_verbose) return;
      if (p - _lastPosLog >= const Duration(milliseconds: 500)) {
        _lastPosLog = p;
        _logInfo('position: $p');
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (_verbose) _logInfo('complete: Wiedergabe beendet.');
    });
  }

  Future<void> _init() async {
    if (_verbose) {
      _logInfo(
        'Init starte… (platform=$defaultTargetPlatform, '
        'assetRaw="$_assetPathRaw", assetKey="$_assetPath")',
      );
    }
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);

      // Asset einmalig setzen (Preload).
      await _player.setSource(AssetSource(_assetPath));

      // Falls iOS die Dauer erst verzögert liefert: Watchdog für Diagnose.
      unawaited(_durationWatchdog());

      _ready = true;
      if (_verbose) _logInfo('Init ok. Player bereit.');
    } on Object catch (e, st) {
      _ready = false;
      _logErr(
        'Init fehlgeschlagen. Existiert die Datei und ist sie in pubspec.yaml deklariert? '
        '(pubspec: z. B. assets/audio/session_timer_end.wav; assetKey im Code: "$_assetPath")',
        e,
        st,
      );
    }
  }

  Future<void> _durationWatchdog() async {
    // Wenn nach 2s noch keine Dauer gemeldet wurde, deutliche Warnung.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_duration == null) {
      _logWarn(
        'Noch keine "duration" empfangen. Mögliche Ursachen: '
        'falscher Asset-Key, Asset nicht im Bundle, ungewöhnlicher WAV-Codec/Header, '
        'oder Abspielen wird sofort gestoppt.',
      );
    }
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    if (_initFuture != null) await _initFuture;
    if (_ready) return;
    _initFuture = _init();
    await _initFuture;
  }

  // ---------------
  // Public API
  // ---------------
  /// Spielt den Ton ab. Schneidet nicht ab, setzt nicht neu die Source.
  Future<void> play() async {
    await _ensureReady();
    if (!_ready) {
      _logWarn(
        'play(): Asset nicht verfügbar → Abbruch (assetKey="$_assetPath").',
      );
      return;
    }

    try {
      if (_verbose) _logInfo('play(): start (seek→0, resume)…');
      await _player.seek(Duration.zero);
      await _player.resume();
    } on Object catch (e, st) {
      _logErr('play() fehlgeschlagen.', e, st);
    }
  }

  /// Spielt ab und wartet bis zum Ende (oder Timeout).
  Future<void> playAndWait({Duration? timeout}) async {
    await _ensureReady();
    if (!_ready) {
      _logWarn(
        'playAndWait(): Asset nicht verfügbar → Abbruch (assetKey="$_assetPath").',
      );
      return;
    }

    try {
      if (_verbose) _logInfo('playAndWait(): start…');
      await _player.seek(Duration.zero);
      await _player.resume();

      final f = _player.onPlayerComplete.first;
      if (timeout == null) {
        await f;
      } else {
        await f.timeout(
          timeout,
          onTimeout: () {
            _logWarn('playAndWait(): Timeout nach $timeout erreicht.');
          },
        );
      }
      if (_verbose) _logInfo('playAndWait(): fertig.');
    } on Object catch (e, st) {
      _logErr('playAndWait() fehlgeschlagen.', e, st);
    }
  }

  /// Stoppt die Wiedergabe (falls aktiv).
  Future<void> stop() async {
    try {
      if (_verbose) _logInfo('stop(): angefordert.');
      await _player.stop();
    } on Object catch (e, st) {
      _logErr('stop() fehlgeschlagen.', e, st);
    }
  }

  /// Gibt Ressourcen frei. Nicht während laufender Wiedergabe aufrufen,
  /// wenn der Sound noch laufen soll (sonst "Klick").
  Future<void> dispose() async {
    try {
      if (_verbose) _logInfo('dispose(): Player wird freigegeben.');
      await _stateSub?.cancel();
      await _durSub?.cancel();
      await _posSub?.cancel();
      await _completeSub?.cancel();
      await _player.dispose();
      if (_verbose) _logInfo('dispose(): ok.');
    } on Object catch (e, st) {
      _logErr('dispose() fehlgeschlagen.', e, st);
    }
  }

  // -------------------------
  // Globale Audio-Konfiguration
  // -------------------------
  /// Optional, aber empfohlen: in `main()` vor der ersten Player-Erzeugung aufrufen.
  static Future<void> configureGlobalAudioContext() async {
    try {
      _logInfo('configureGlobalAudioContext(): setze AudioContext…');
      await AudioPlayer.global.setAudioContext(
        const AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [AVAudioSessionOptions.mixWithOthers],
          ),
          android: AudioContextAndroid(
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.music,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      _logInfo('configureGlobalAudioContext(): ok.');
    } on Object catch (e, st) {
      _logErr(
        'configureGlobalAudioContext(): fehlgeschlagen (verwende Defaults).',
        e,
        st,
      );
    }
  }
}
