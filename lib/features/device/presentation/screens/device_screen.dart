import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/widgets/device_session_section.dart';

class DeviceScreen extends StatefulWidget {
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
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
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
    final key = _sessionKey;
    if (key != null) {
      final controller = context.read<WorkoutDayController>();
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

    final controller = context.watch<WorkoutDayController>();
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

    return Scaffold(
      body: SafeArea(
        child: DeviceSessionSection(
          provider: session.provider,
          gymId: session.gymId,
          deviceId: session.deviceId,
          exerciseId: session.exerciseId,
          userId: session.userId,
          sessionKey: session.key,
          plannedEntry: null,
          onSessionSaved: _handleSessionSaved,
          onCloseRequested: _handleCloseRequested,
        ),
      ),
    );
  }
}
