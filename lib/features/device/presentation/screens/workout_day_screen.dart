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

  Future<void> _handleAddSession() async {
    final selection = await _openGymSelection();
    if (!mounted || selection == null) {
      return;
    }
    _handleSelection(selection);
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
    if (_sessionKey == null) {
      _sessionKey = session.key;
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 120;
      _scrollController.animateTo(
        target,
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
    if (closed && controller.activeSessions().isEmpty) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkoutDayController>();
    final sessions = controller.activeSessions();
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
          onPressed: () async {
            final selection = await _openGymSelection();
            if (!mounted || selection == null) {
              return;
            }
            _handleSelection(selection);
          },
        ),
        title: Text(loc.multiDeviceNewExercise),
        actions: [
          NfcScanButton(
            onSelection: (selection) async {
              _handleSelection(selection);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleAddSession,
            tooltip: loc.multiDeviceNewExercise,
          ),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: CustomScrollView(
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
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final session = sessions[index];
                        final builder = widget.sessionBuilder;
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
            ],
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
    await settings.load(auth.userId!);

    final plannedRest = <String, int?>{
      for (var i = 0; i < sessions.length; i++)
        sessions[i].key: plannedEntries[i]?.restInSeconds,
    };

    final result = await controller.saveAllSessions(
      userId: auth.userId!,
      showInLeaderboard: auth.showInLeaderboard ?? true,
      userName: auth.userName,
      gender: settings.gender,
      bodyWeightKg: settings.bodyWeightKg,
      plannedRestSecondsBySession: plannedRest,
    );

    if (!mounted) return;
    if (result.attempted == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.noCompletedSets)));
      return;
    }

    if (result.hasFailures) {
      final firstError = result.failedSessions.values.firstWhere(
        (error) => error != null && error.isNotEmpty,
        orElse: () => null,
      );
      final message = firstError ?? '${loc.errorPrefix}: ${result.failedSessions.length}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final savedText = result.saved == 1
        ? loc.sessionSaved
        : '${loc.sessionSaved} (${result.saved}/${result.attempted})';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(savedText)));
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
