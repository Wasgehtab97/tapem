import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/features/nfc/providers/nfc_providers.dart';

import '../../../bootstrap/navigation.dart';

class GlobalNfcListener extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalNfcListener({required this.child, super.key});

  @override
  ConsumerState<GlobalNfcListener> createState() => _GlobalNfcListenerState();
}

class _GlobalNfcListenerState extends ConsumerState<GlobalNfcListener> {
  late final ReadNfcCode _reader;
  late final GetDeviceByNfcCode _getDevice;
  late final AuthProvider _auth;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      _reader = ref.read(readNfcCodeProvider);
      _getDevice = ref.read(getDeviceByNfcCodeProvider);
      _auth = ref.read(authControllerProvider);

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
            final container =
                ProviderScope.containerOf(navContext, listen: false);
            final controller =
                container.read(workoutDayControllerProvider);
            final userId = _auth.userId;
            if (userId != null) {
              controller.addOrFocusSession(
                gymId: gymId,
                deviceId: dev.uid,
                exerciseId: dev.uid,
                userId: userId,
              );
            }
          }
          final timer = navContext == null
              ? null
              : ProviderScope.containerOf(navContext, listen: false)
                  .read(workoutSessionDurationServiceProvider);
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
