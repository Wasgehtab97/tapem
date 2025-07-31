import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart' as auth;
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';

import '../../../main.dart'; // für navigatorKey

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
            arguments: {'gymId': gymId, 'deviceId': dev.id},
          );
        } else {
          navigatorKey.currentState?.pushNamed(
            AppRouter.device,
            arguments: {
              'gymId': gymId,
              'deviceId': dev.id,
              'exerciseId': dev.id,
            },
          );
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
