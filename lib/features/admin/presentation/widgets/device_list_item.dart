// lib/features/admin/presentation/widgets/device_list_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceColor = colorScheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.5 : 0.9,
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      color: surfaceColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.18),
          child: Text(
            '${device.id}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(device.name, style: theme.textTheme.titleMedium),
        subtitle: device.description.isNotEmpty
            ? Text(
                device.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Wrap(
          spacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.nfc),
              tooltip: loc.deviceWriteNfcTooltip,
              onPressed: device.nfcCode != null
                  ? () async {
                      try {
                        await writeUC.execute(device.nfcCode!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.adminDeviceNfcWritten)),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.adminDeviceNfcWriteError(e.toString()),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.delete),
              tooltip: loc.deviceDeleteTooltip,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
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

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.deviceDeleteSuccess)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
