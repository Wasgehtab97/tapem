import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/training_plan/domain/models/exercise_entry.dart';
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

  Future<void> _handleAddSession() async {
    final selection = await Navigator.of(context)
        .push<WorkoutDeviceSelection>(
      MaterialPageRoute(
        builder: (routeContext) => GymScreen(
          selectionMode: true,
          onSelect: (result) => Navigator.of(routeContext).pop(result),
        ),
      ),
    );
    if (!mounted || selection == null) {
      return;
    }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 120;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    if (_sessionKey == null) {
      _sessionKey = session.key;
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddSession,
        tooltip: loc.multiDeviceNewExercise,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: sessions.isEmpty
            ? const SizedBox.shrink()
            : Scrollbar(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
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
                ),
              ),
      ),
    );
  }
}
