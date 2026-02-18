import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/device/providers/workout_entry_orchestrator_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
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
  StreamSubscription<String>? _nfcSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      _reader = ref.read(readNfcCodeProvider);
      _getDevice = ref.read(getDeviceByNfcCodeProvider);
      _auth = ref.read(authControllerProvider);

      _nfcSubscription = _reader.execute().listen((code) async {
        if (code.isEmpty) return;
        final gymId = _auth.gymCode;
        if (gymId == null) return;
        final userId = _auth.userId;
        if (userId == null) return;

        final dev = await _getDevice.execute(gymId, code);
        if (dev == null) return;

        // Physisches Feedback bei Erfolg
        HapticFeedback.mediumImpact();

        if (dev.isMulti) {
          // Bei Multi-Geräten zur Übungsauswahl navigieren.
          navigatorKey.currentState?.pushNamed(
            AppRouter.exerciseList,
            arguments: {'gymId': gymId, 'deviceId': dev.uid},
          );
        } else {
          // Einzelsitzung hinzufügen/fokussieren.
          final orchestrator = ref.read(workoutEntryOrchestratorProvider);
          final controller = ref.read(workoutDayControllerProvider);
          final coordinator = ref.read(workoutSessionCoordinatorProvider);
          final result = await orchestrator.addOrFocusFromExternalSource(
            controller: controller,
            coordinator: coordinator,
            gymId: gymId,
            deviceId: dev.uid,
            exerciseId: dev.uid,
            exerciseName: dev.name,
            userId: userId,
          );

          // Visuelle Bestätigung
          final context = navigatorKey.currentContext;
          if (!result.isDuplicate && context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Übung "${dev.name}" wurde hinzugefügt'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Navigation zum aktiven Workout (Tab 2).
          // Wir nutzen pushNamedAndRemoveUntil zum HomeScreen, falls wir woanders sind.
          // Die HomeScreen-Logik erkennt den aktiven Timer und stellt den Tab ein.
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRouter.home,
            (route) => false,
            arguments: 2,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _nfcSubscription?.cancel();
    NfcManager.instance.stopSession();
    super.dispose();
  }
}
