import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/services/membership_service.dart';

class NfcScanButton extends StatelessWidget {
  const NfcScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.read<AuthProvider>();
    final getDeviceUC = context.read<GetDeviceByNfcCode>();
    final membership = context.read<MembershipService>();

    return IconButton(
      icon: const Icon(Icons.nfc),
      onPressed: () async {
        // Alte Session beenden (falls offen)
        try {
          await NfcManager.instance.stopSession();
        } catch (_) {}
        // Neue Session starten
        try {
          await NfcManager.instance.startSession(
            pollingOptions: {NfcPollingOption.iso14443},
            onDiscovered: (tag) async {
              String code = '';
              try {
                final ndef = Ndef.from(tag);
                final records = ndef?.cachedMessage?.records;
                if (records != null && records.isNotEmpty) {
                  final payload = records.first.payload.skip(3);
                  code = String.fromCharCodes(payload);
                }
              } catch (_) {
                code = '';
              } finally {
                await NfcManager.instance.stopSession();
              }

              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kein NFC-Code erkannt')),
                );
                return;
              }

              final gymId = authProv.gymCode;
              if (gymId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kein Gym ausgewählt')),
                );
                return;
              }

              final dev = await getDeviceUC.execute(gymId, code);
              if (dev == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gerät nicht gefunden')),
                );
                return;
              }

              await membership.ensureMembership(gymId, authProv.userId!);

              // Navigation basierend auf dev.isMulti
              if (dev.isMulti) {
                Navigator.of(context).pushNamed(
                  AppRouter.exerciseList,
                  arguments: {'gymId': gymId, 'deviceId': dev.uid},
                );
              } else {
                Navigator.of(context).pushNamed(
                  AppRouter.device,
                  arguments: {
                    'gymId': gymId,
                    'deviceId': dev.uid,
                    'exerciseId': dev.uid,
                  },
                );
              }
            },
          );
        } catch (error) {
          // Session bei Fehler beenden
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('NFC-Fehler: $error')));
        }
      },
    );
  }
}
