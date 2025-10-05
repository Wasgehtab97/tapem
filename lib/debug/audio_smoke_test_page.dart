import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/audio/timer_chime_player.dart';

class AudioSmokeTestPage extends StatefulWidget {
  const AudioSmokeTestPage({super.key});

  @override
  State<AudioSmokeTestPage> createState() => _AudioSmokeTestPageState();
}

class _AudioSmokeTestPageState extends State<AudioSmokeTestPage> {
  late final TimerChimePlayer _player;
  final _uuid = const Uuid();

  PlayerState _state = PlayerState.stopped;
  Duration? _duration;
  Duration _position = Duration.zero;
  String? _lastTimerId;
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _player = TimerChimePlayer();
    _player.stateNotifier.addListener(_updateState);
    _player.durationNotifier.addListener(_updateDuration);
    _player.positionNotifier.addListener(_updatePosition);
  }

  @override
  void dispose() {
    _player.stateNotifier.removeListener(_updateState);
    _player.durationNotifier.removeListener(_updateDuration);
    _player.positionNotifier.removeListener(_updatePosition);
    _player.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _state = _player.stateNotifier.value;
    });
  }

  void _updateDuration() {
    setState(() {
      _duration = _player.durationNotifier.value;
    });
  }

  void _updatePosition() {
    setState(() {
      _position = _player.positionNotifier.value;
    });
  }

  Future<void> _triggerPlayback() async {
    final timerId = _uuid.v4();
    setState(() {
      _lastTimerId = timerId;
      _status = 'Preparing…';
    });
    await _player.configureForTimer(timerId: timerId);
    setState(() {
      _status = 'Playing';
    });
    await _player.play(timerId: timerId);
    final completed = await _player.waitForCompletion(timerId: timerId);
    setState(() {
      _status = completed ? 'Completed' : 'Timeout';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationLabel =
        _duration != null ? '${_duration!.inMilliseconds} ms' : '—';
    final positionLabel = '${_position.inMilliseconds} ms';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Smoke Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _triggerPlayback,
              child: const Text('Play Chime'),
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'Last timerId', value: _lastTimerId ?? '—'),
            _InfoRow(label: 'Status', value: _status),
            _InfoRow(label: 'State', value: _state.name),
            _InfoRow(label: 'Duration', value: durationLabel),
            _InfoRow(label: 'Position', value: positionLabel),
            const SizedBox(height: 16),
            Text(
              'Check the terminal logs for AUDIO_* and TIMER_* events with the timerId above.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
