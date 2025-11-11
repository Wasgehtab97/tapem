import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/training_plan/domain/models/exercise_entry.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';
import 'package:tapem/l10n/app_localizations.dart';

class WorkoutDayScreen extends StatefulWidget {
  const WorkoutDayScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    this.sessionBuilder,
    this.closeSessionOnDispose = false,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;
  final Widget Function(
    BuildContext context,
    WorkoutDaySession session,
    ExerciseEntry? plannedEntry,
  )?
      sessionBuilder;
  final bool closeSessionOnDispose;

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _sessionKey;
  bool _isInitializing = true;
  bool _ownsSession = false;

  Future<WorkoutDeviceSelection?> _openGymSelection() {
    return Navigator.of(context).push<WorkoutDeviceSelection>(
      MaterialPageRoute(
        builder: (routeContext) => GymScreen(
          selectionMode: true,
          onSelect: (result) => Navigator.of(routeContext).pop(result),
        ),
      ),
    );
  }

  void _handleSelection(WorkoutDeviceSelection selection) {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
    final session = controller.addOrFocusSession(
      gymId: selection.gymId,
      deviceId: selection.deviceId,
      exerciseId: selection.exerciseId,
      userId: auth.userId!,
    );
    if (!mounted) return;
    setState(() {});
    _scrollToLatest();
    _sessionKey ??= session.key;
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
    final contextKey = WorkoutDayController.contextKey(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: auth.userId!,
    );
    final alreadyExists = controller.sessionForKey(contextKey) != null;
    final session = controller.addOrFocusSession(
      gymId: widget.gymId,
      deviceId: widget.deviceId,
      exerciseId: widget.exerciseId,
      userId: auth.userId!,
    );
    if (mounted) {
      setState(() {
        _sessionKey = session.key;
        _isInitializing = false;
        if (!alreadyExists) {
          _ownsSession = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final key = _sessionKey;
    if (widget.closeSessionOnDispose && key != null && _ownsSession) {
      final controller = context.read<WorkoutDayController>();
      if (controller.sessionForKey(key) != null) {
        controller.closeSession(key);
      }
    }
    super.dispose();
  }

  void _handleCloseSession(WorkoutDaySession session) {
    final controller = context.read<WorkoutDayController>();
    final closed = controller.closeSession(session.key);
    if (closed && session.key == _sessionKey) {
      _sessionKey = null;
      _ownsSession = false;
    }
    if (!mounted) return;
    if (!closed) {
      setState(() {});
      return;
    }
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    final activeGymId = auth.gymCode ?? session.gymId;
    final remaining = (userId == null)
        ? const <WorkoutDaySession>[]
        : controller.sessionsFor(userId: userId, gymId: activeGymId);
    if (remaining.isEmpty) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkoutDayController>();
    final auth = context.watch<AuthProvider>();
    final activeGymId = auth.gymCode ?? widget.gymId;
    final userId = auth.userId;
    final sessions = (userId == null)
        ? const <WorkoutDaySession>[]
        : controller.sessionsFor(userId: userId, gymId: activeGymId);
    final trainingPlanProvider = context.watch<TrainingPlanProvider>();
    final currentDate = DateTime.now();
    final List<ExerciseEntry?> plannedEntries = [
      for (final session in sessions)
        trainingPlanProvider.entryForDate(
          session.deviceId,
          session.exerciseId,
          currentDate,
        ),
    ];

    final loc = AppLocalizations.of(context)!;

    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        titleSpacing: 0,
        toolbarHeight: kToolbarHeight + 8,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ActiveWorkoutTimer(
            key: ValueKey('workoutDayTimer-${_sessionKey ?? 'global'}'),
            compact: true,
            padding: EdgeInsets.zero,
            sessionKey: _sessionKey,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 8),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: NfcScanButton(
              onBeforeOpen: () => FocusManager.instance.primaryFocus?.unfocus(),
              onSelection: (selection) async {
                _handleSelection(selection);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: Consumer<OverlayNumericKeypadController>(
            builder: (context, keypadController, _) {
              final bottomSpacerHeight = keypadController.keypadContentHeight +
                  MediaQuery.of(context).padding.bottom +
                  12;
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (sessions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          loc.multiDeviceNewExercise,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    )
                  else ...[
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final session = sessions[index];
                            final builder = widget.sessionBuilder;
                            final displayIndex = sessions.length - index;
                            if (builder != null) {
                              return builder(
                                context,
                                session,
                                plannedEntries[index],
                              );
                            }
                            return DeviceSessionSection(
                              key: ValueKey(session.key),
                              provider: session.provider,
                              gymId: session.gymId,
                              deviceId: session.deviceId,
                              exerciseId: session.exerciseId,
                              userId: session.userId,
                              displayIndex: displayIndex,
                              sessionKey: session.key,
                              plannedEntry: plannedEntries[index],
                              onCloseRequested: () => _handleCloseSession(session),
                            );
                          },
                          childCount: sessions.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SaveAllButton(
                        isSaving: controller.isSaving,
                        canSave: controller.canSave,
                        onPressed: () => _handleSaveAllSessions(
                          sessions,
                          plannedEntries,
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomSpacerHeight),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveAllSessions(
    List<WorkoutDaySession> sessions,
    List<ExerciseEntry?> plannedEntries,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final controller = context.read<WorkoutDayController>();
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();

    final confirmFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trainingstag abschließen?'),
        content: const Text(
            'Möchtest du alle offenen Sessions speichern und den Trainingstag beenden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.saveButton),
          ),
        ],
      ),
    );

    if (!mounted || confirmFinish != true) {
      return;
    }

    final sessionsByKey = {
      for (final session in sessions) session.key: session,
    };
    final sessionsWithPendingSets = <WorkoutDaySession>[
      for (final session in sessions)
        if (session.provider.getSetCounts().filledNotDone > 0) session,
    ];

    if (sessionsWithPendingSets.isNotEmpty) {
      final confirmCompleteAll = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.notAllSetsConfirmed),
          content: const Text(
            'Es wurden noch nicht alle Sätze abgehakt. Möchtest du alle offenen Sätze abhaken und fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.confirmAllSets),
            ),
          ],
        ),
      );

      if (!mounted || confirmCompleteAll != true) {
        return;
      }

      for (final session in sessionsWithPendingSets) {
        session.provider.completeAllFilledNotDone();
      }
    }

    await settings.load(auth.userId!);

    final plannedRest = <String, int?>{
      for (var i = 0; i < sessions.length; i++)
        sessions[i].key: plannedEntries[i]?.restInSeconds,
    };

    final activeGymId = auth.gymCode ?? widget.gymId;

    final result = await controller.saveAllSessions(
      userId: auth.userId!,
      gymId: activeGymId,
      showInLeaderboard: auth.showInLeaderboard ?? true,
      userName: auth.userName,
      gender: settings.gender,
      bodyWeightKg: settings.bodyWeightKg,
      plannedRestSecondsBySession: plannedRest,
    );

    if (!mounted) return;

    if (result.saved > 0) {
      for (final key in result.savedSessionKeys) {
        final session = sessionsByKey[key];
        if (session == null) continue;
        final closed = controller.closeSession(key);
        if (closed && key == _sessionKey) {
          _sessionKey = null;
          _ownsSession = false;
        }
      }
      final remaining = controller.sessionsFor(
        userId: auth.userId!,
        gymId: activeGymId,
      );
      if (remaining.isEmpty) {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      } else {
        setState(() {});
      }
    }

      final message = () {
        if (result.attempted == 0) {
          return loc.noCompletedSets;
        }
        if (result.saved == 0) {
          final firstError = result.failedSessions.values.firstWhere(
            (error) => error != null && error.isNotEmpty,
            orElse: () => null,
          );
          return firstError ?? '${loc.errorPrefix}: ${result.failedSessions.length}';
        }
        final savedText = result.saved == result.attempted
            ? loc.sessionSaved
            : '${loc.sessionSaved} (${result.saved}/${result.attempted})';
        if (!result.hasFailures) {
          return savedText;
        }
        final firstError = result.failedSessions.values.firstWhere(
          (error) => error != null && error.isNotEmpty,
          orElse: () => null,
        );
        final failureText =
            firstError ?? '${loc.errorPrefix}: ${result.failedSessions.length}';
        return '$savedText\n$failureText';
      }();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

class _SaveAllButton extends StatelessWidget {
  const _SaveAllButton({
    required this.isSaving,
    required this.canSave,
    required this.onPressed,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: !canSave || isSaving ? null : onPressed,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ),
    );
  }
}
