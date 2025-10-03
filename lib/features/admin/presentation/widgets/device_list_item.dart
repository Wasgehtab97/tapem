// lib/features/admin/presentation/widgets/device_list_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/delete_device_usecase.dart';
import 'package:tapem/features/nfc/domain/usecases/write_nfc_tag.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;

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
            tooltip: loc.deviceWriteNfcTooltip,
            onPressed:
                device.nfcCode != null
                    ? () async {
                      try {
                        await writeUC.execute(device.nfcCode!);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(loc.adminDeviceNfcWritten)));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.adminDeviceNfcWriteError(e.toString()))),
                        );
                      }
                    }
                    : null,
          ),

          // Gerät löschen
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: loc.deviceDeleteTooltip,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Text(loc.deviceDeleteDialogTitle),
                      content: Text(loc.deviceDeleteDialogMessage(device.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(loc.commonCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(loc.commonDelete),
                        ),
                      ],
                    ),
              );
              if (confirm != true) return;

              // Token erneuern (Custom-Claims)
              final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
              if (fbUser != null) await fbUser.getIdToken(true);

              await deleteUC.execute(gymId: gymId, deviceId: device.uid);
              onDeleted();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(loc.deviceDeleteSuccess)));
            },
          ),
        ],
      ),
    );
  }
}
