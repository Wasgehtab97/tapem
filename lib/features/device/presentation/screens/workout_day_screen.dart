import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';
import 'package:tapem/features/training_plan/domain/models/exercise_entry.dart';

class WorkoutDayScreen extends StatefulWidget {
  const WorkoutDayScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });

  final String gymId;
  final String deviceId;
  final String exerciseId;

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _sessionKey;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final auth = context.read<AuthProvider>();
    final controller = context.read<WorkoutDayController>();
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
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final key = _sessionKey;
    if (key != null) {
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

    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
