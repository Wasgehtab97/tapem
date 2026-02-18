
import 'dart:ui';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tapem/ui/timer/session_timer_service.dart';

class SessionRestTimer extends StatefulWidget {
  const SessionRestTimer({
    super.key,
    this.initialSeconds,
    this.onInteraction,
    this.onDurationChanged,
    this.compact = false,
    this.inline = false,
    this.showLabel = true,
  });

  final int? initialSeconds;
  final VoidCallback? onInteraction;
  final ValueChanged<int>? onDurationChanged;
  final bool compact;
  final bool inline;
  final bool showLabel;

  @override
  SessionRestTimerState createState() => SessionRestTimerState();
}

class SessionRestTimerState extends State<SessionRestTimer> {
  late final SessionTimerService _service;
  late final VoidCallback _doneListener;
  static final AudioPlayer _player = AudioPlayer();
  static bool _audioContextSet = false;
  static final Uint8List _beepBytes = _buildBeep();

  SessionTimerService get service => _service;

  @override
  void initState() {
    super.initState();
    _ensureAudioContext();
    _service = SessionTimerService(
      initialDuration: _initialDurationFrom(widget.initialSeconds),
    );
    _doneListener = () {
      _playDoneSound();
      HapticFeedback.mediumImpact();
    };
    _service.addDoneListener(_doneListener);
  }

  @override
  void didUpdateWidget(covariant SessionRestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSeconds != oldWidget.initialSeconds) {
      applyInitialSeconds(widget.initialSeconds);
    }
  }

  @override
  void dispose() {
    _service.removeDoneListener(_doneListener);
    _service.dispose();
    super.dispose();
  }

  void _ensureAudioContext() {
    if (_audioContextSet) return;
    _audioContextSet = true;
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  Future<void> _playDoneSound() async {
    try {
      await _player.play(BytesSource(_beepBytes), volume: 1.0);
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void applyInitialSeconds(int? seconds) {
    final duration = _initialDurationFrom(seconds);
    if (duration != null) {
      _service.applyInitialDuration(duration);
    }
  }

  Duration? _initialDurationFrom(int? seconds) {
    if (seconds == null) {
      return null;
    }
    return Duration(seconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final size = isCompact ? 38.0 : 44.0;
    final stroke = isCompact ? 3.0 : 3.6;

    Widget dial = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onInteraction?.call();
        if (_service.isRunning) {
          _service.stop();
        } else {
          _service.start();
        }
      },
      onLongPress: () => _handleTimerTap(context),
      child: SizedBox(
        width: size,
        height: size,
        child: ValueListenableBuilder<Duration>(
          valueListenable: _service.remaining,
          builder: (context, remaining, _) {
            final totalMillis = _service.total.inMilliseconds;
            final progress = totalMillis == 0
                ? 0.0
                : 1 -
                    (remaining.inMilliseconds / totalMillis)
                        .clamp(0.0, 1.0);
            final isRunning = _service.isRunning;
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -1.57,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: stroke,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      accent.withOpacity(0.85),
                    ),
                  ),
                ),
                Container(
                  width: size - stroke * 2.4,
                  height: size - stroke * 2.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.18),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: isCompact ? 15 : 17,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final label = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTimerTap(context),
      child: ValueListenableBuilder<Duration>(
        valueListenable: _service.remaining,
        builder: (context, remaining, _) {
          final displaySeconds = remaining.inSeconds % 60;
          final displayMinutes = remaining.inMinutes;
          final timeLabel =
              '${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}';
          return Text(
            timeLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
        },
      ),
    );

    if (widget.inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dial,
          if (widget.showLabel) ...[
            const SizedBox(width: 6),
            label,
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dial,
        if (widget.showLabel) ...[
          const SizedBox(height: 4),
          label,
        ],
      ],
    );
  }

  Future<void> _handleTimerTap(BuildContext context) async {
    widget.onInteraction?.call();
    final durations = _service.availableDurations;
    final selectedDuration = _service.selectedDuration.inSeconds;
    final chosenSeconds = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.8),
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(context);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14171A).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pausenzeit wählen', // localized later if needed, hardcode for now or use passed param
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: durations.length,
                      itemBuilder: (context, i) {
                        final seconds = durations[i];
                        final isSelected = seconds == selectedDuration;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(seconds),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${seconds}s',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || chosenSeconds == null) {
      return;
    }
    final index = durations.indexOf(chosenSeconds);
    if (index == -1) {
      return;
    }
    final delta = index - _service.selectedIndex;
    if (delta != 0) {
      widget.onInteraction?.call();
      _service.changeDuration(delta);
      widget.onDurationChanged?.call(chosenSeconds);
    }
  }

  static Uint8List _buildBeep() {
    const sampleRate = 16000;
    const seconds = 0.25;
    const freq = 1100.0;
    final totalSamples = (sampleRate * seconds).round();
    final bytes = BytesBuilder();

    // WAV header
    final byteRate = sampleRate * 2; // mono 16-bit
    final dataSize = totalSamples * 2;
    final fileSize = 44 + dataSize - 8;
    void w32(int v) => bytes.add([
          v & 0xff,
          (v >> 8) & 0xff,
          (v >> 16) & 0xff,
          (v >> 24) & 0xff
        ]);
    void w16(int v) => bytes.add([v & 0xff, (v >> 8) & 0xff]);

    bytes.add('RIFF'.codeUnits);
    w32(fileSize);
    bytes.add('WAVEfmt '.codeUnits);
    w32(16); // PCM chunk size
    w16(1); // PCM format
    w16(1); // channels
    w32(sampleRate);
    w32(byteRate);
    w16(2); // block align
    w16(16); // bits per sample
    bytes.add('data'.codeUnits);
    w32(dataSize);

    // samples
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final amp = (0.35 *
              (1 - (i / totalSamples)) *
              32767 *
              math.sin(2 * math.pi * freq * t))
          .round()
          .clamp(-32767, 32767);
      w16(amp);
    }
    return bytes.toBytes();
  }
}
