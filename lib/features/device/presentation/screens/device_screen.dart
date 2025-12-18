import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

class DeviceScreen extends riverpod.ConsumerStatefulWidget {
  const DeviceScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;

  @override
  riverpod.ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends riverpod.ConsumerState<DeviceScreen> {
  String? _sessionKey;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final auth = ref.read(authControllerProvider);
    final controller = ref.read(workoutDayControllerProvider);
    final session = controller.addOrFocusSession(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: auth.userId!,
      autoFinalizeEnabled: true,
    );
    if (mounted) {
      setState(() {
        _sessionKey = session.key;
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    final key = _sessionKey;
    if (key != null) {
      final controller = ref.read(workoutDayControllerProvider);
      if (controller.sessionForKey(key) != null) {
        controller.closeSession(key);
      }
    }
    super.dispose();
  }

  void _handleSessionSaved() {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      return name == AppRouter.home || route.isFirst;
    });
  }

  void _handleCloseRequested() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final controller = ref.watch(workoutDayControllerProvider);
    final key = _sessionKey;
    if (key == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final session = controller.sessionForKey(key);
    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: session.provider,
      builder: (context, _) {
        return Scaffold(
          appBar: _buildAppBar(context, ref, session),
          body: SafeArea(
            child: DeviceSessionSection(
              provider: session.provider,
              gymId: session.gymId,
              deviceId: session.deviceId,
              exerciseId: session.exerciseId,
              exerciseName: session.exerciseName,
              userId: session.userId,
              sessionKey: session.key,

              onSessionSaved: _handleSessionSaved,
              onCloseRequested: _handleCloseRequested,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    riverpod.WidgetRef ref,
    WorkoutDaySession session,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final provider = session.provider;
    final device = provider.device;
    final exercises = (device?.isMulti ?? false)
        ? ref.watch(exerciseProvider).exercises
        : null;
    final resolvedTitle = _resolveExerciseTitle(
          provider,
          exercises: exercises,
          exerciseId: session.exerciseId,
        ) ??
        loc.newSessionTitle;
    final subtitle = device?.isMulti == true && resolvedTitle != device?.name
        ? device?.name
        : null;
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.72),
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 12,
        );

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      centerTitle: false,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(resolvedTitle, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(
              subtitle,
              style: subtitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          ActiveWorkoutTimer(
            key: ValueKey('deviceScreenTimer-${session.key}'),
            compact: true,
            padding: EdgeInsets.zero,
            sessionKey: session.key,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: NfcScanButton(
            deviceId: session.deviceId,
            exerciseId: session.exerciseId,
            onBeforeOpen: () => FocusManager.instance.primaryFocus?.unfocus(),
            onSelection: (selection) async {
              final auth = ref.read(authControllerProvider);
              final controller = ref.read(workoutDayControllerProvider);
              controller.addOrFocusSession(
                gymId: selection.gymId,
                deviceId: selection.deviceId,
                exerciseId: selection.exerciseId,
                userId: auth.userId!,
                autoFinalizeEnabled: true,
              );
            },
          ),
        ),
      ],
    );
  }

  String? _resolveExerciseTitle(
    DeviceProvider provider, {
    List<Exercise>? exercises,
    required String exerciseId,
  }) {
    final device = provider.device;
    if (device == null) {
      return null;
    }
    if (!device.isMulti) {
      return device.name;
    }
    final availableExercises = exercises;
    if (availableExercises == null) {
      return device.name;
    }
    final match = availableExercises.where((exercise) => exercise.id == exerciseId);
    if (match.isNotEmpty) {
      return match.first.name;
    }
    return device.name;
  }
}
