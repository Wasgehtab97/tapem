import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart' as auth;
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/app_router.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../main.dart'; // für navigatorKey

class GlobalNfcListener extends StatefulWidget {
  final Widget child;
  const GlobalNfcListener({ required this.child, super.key });

  @override
  State<GlobalNfcListener> createState() => _GlobalNfcListenerState();
}

class _GlobalNfcListenerState extends State<GlobalNfcListener> {
  late final GetDeviceByNfcCode _getDevice;
  late final auth.AuthProvider _auth;
  late final Stream<String> _nfcStream;
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      _subscribed = true;

      // UseCases / Provider holen
      _nfcStream = context.read<ReadNfcCode>().execute();
      _getDevice = GetDeviceByNfcCode(context.read());
      _auth = context.read<auth.AuthProvider>();

      // Auf jeden neuen NFC-String hören
      _nfcStream.listen((code) async {
        if (code.isEmpty) return;
        final gymId = _auth.gymCode;
        if (gymId == null) return;
        final device = await _getDevice.execute(gymId, code);
        if (device != null) {
          navigatorKey.currentState
              ?.pushNamed(AppRouter.device, arguments: device.id);
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
