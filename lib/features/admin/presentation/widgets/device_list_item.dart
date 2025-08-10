// lib/features/admin/presentation/widgets/device_list_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/delete_device_usecase.dart';
import 'package:tapem/features/nfc/domain/usecases/write_nfc_tag.dart';

class DeviceListItem extends StatelessWidget {
  final Device device;
  final VoidCallback onDeleted;

  const DeviceListItem({
    Key? key,
    required this.device,
    required this.onDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final writeUC = context.read<WriteNfcTagUseCase>();
    final deleteUC = context.read<DeleteDeviceUseCase>();
    final gymId = context.read<AuthProvider>().gymCode!;

    return ListTile(
      leading: Text('${device.id}'),
      title: Text(device.name),
      subtitle: device.description.isNotEmpty ? Text(device.description) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // NFC-Tag beschreiben
          IconButton(
            icon: const Icon(Icons.nfc),
            tooltip: 'NFC-Tag beschreiben',
            onPressed:
                device.nfcCode != null
                    ? () async {
                      try {
                        await writeUC.execute(device.nfcCode!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('NFC-Tag geschrieben')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler beim Schreiben: $e')),
                        );
                      }
                    }
                    : null,
          ),

          // Gerät löschen
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Gerät löschen',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Gerät löschen?'),
                      content: Text(
                        'Soll das Gerät "${device.name}" wirklich gelöscht werden?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Löschen'),
                        ),
                      ],
                    ),
              );
              if (confirm != true) return;

              // Token erneuern (Custom-Claims)
              final fbUser = context.read<fb_auth.FirebaseAuth>().currentUser;
              if (fbUser != null) await fbUser.getIdToken(true);

              await deleteUC.execute(gymId: gymId, deviceId: device.uid);
              onDeleted();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Gerät gelöscht')));
            },
          ),
        ],
      ),
    );
  }
}
