import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart' as auth;
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';

import '../../../bootstrap/navigation.dart';

class GlobalNfcListener extends StatefulWidget {
  final Widget child;
  const GlobalNfcListener({required this.child, super.key});

  @override
  State<GlobalNfcListener> createState() => _GlobalNfcListenerState();
}

class _GlobalNfcListenerState extends State<GlobalNfcListener> {
  late final ReadNfcCode _reader;
  late final GetDeviceByNfcCode _getDevice;
  late final auth.AuthProvider _auth;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      _reader = context.read<ReadNfcCode>();
      _getDevice = context.read<GetDeviceByNfcCode>();
      _auth = context.read<auth.AuthProvider>();

      _reader.execute().listen((code) async {
        if (code.isEmpty) return;
        final gymId = _auth.gymCode;
        if (gymId == null) return;
        final dev = await _getDevice.execute(gymId, code);
        if (dev == null) return;

        if (dev.isMulti) {
          navigatorKey.currentState?.pushNamed(
            AppRouter.exerciseList,
            arguments: {'gymId': gymId, 'deviceId': dev.uid},
          );
        } else {
          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            try {
              final controller =
                  navContext.read<WorkoutDayController>();
              final userId = _auth.userId;
              if (userId != null) {
                controller.addOrFocusSession(
                  gymId: gymId,
                  deviceId: dev.uid,
                  exerciseId: dev.uid,
                  userId: userId,
                );
              }
            } on ProviderNotFoundException {
              // ignore missing controller
            }
          }
          final timer = navContext?.read<WorkoutSessionDurationService>();
          if (timer != null && timer.isRunning) {
            navigatorKey.currentState?.pushNamed(
              AppRouter.home,
              arguments: 2,
            );
          } else {
            navigatorKey.currentState?.pushNamed(
              AppRouter.workoutDay,
              arguments: {
                'gymId': gymId,
                'deviceId': dev.uid,
                'exerciseId': dev.uid,
              },
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}
