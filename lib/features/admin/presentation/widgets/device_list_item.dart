// lib/features/admin/presentation/widgets/device_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:tapem/features/admin/presentation/widgets/device_form_dialog.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/delete_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_device_usecase.dart'; // NEW
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/nfc/domain/usecases/write_nfc_tag.dart';
import 'package:tapem/features/nfc/providers/nfc_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DeviceListItem extends ConsumerWidget {
  final Device device;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated; // NEW
  final List<MuscleGroup> muscleGroups; // NEW

  const DeviceListItem({
    Key? key,
    required this.device,
    required this.onDeleted,
    required this.onUpdated,
    required this.muscleGroups,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final container = ProviderScope.containerOf(context, listen: false);
    final writeUC = container.read(writeNfcTagUseCaseProvider);
    final deleteUC = container.read(deleteDeviceUseCaseProvider);
    final updateUC = container.read(updateDeviceUseCaseProvider); // NEW
    final gymId = ref.read(authControllerProvider).gymCode;
    if (gymId == null) {
      return const SizedBox.shrink();
    }
    final loc = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return PremiumActionTile(
      leading: Icon(
        device.isMulti ? Icons.hub_rounded : Icons.fitness_center_rounded,
      ),
      title: device.name,
      subtitle: device.displaySubtitle,
      accentColor: brandColor,
      trailingLeading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandColor.withOpacity(0.2), width: 1),
            ),
            child: Text(
              'ID: ${device.id}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: brandColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _DeviceAdminActions(
            device: device,
            gymId: gymId,
            muscleGroups: muscleGroups,
            onUpdated: onUpdated,
            onDeleted: onDeleted,
            writeUC: writeUC,
            deleteUC: deleteUC,
            updateUC: updateUC,
            loc: loc,
          ),
        ],
      ),
      onTap: () {
        // Optional: Could open edit dialog on tap as well
      },
    );
  }
}

class _DeviceAdminActions extends ConsumerWidget {
  final Device device;
  final String gymId;
  final List<MuscleGroup> muscleGroups;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;
  final WriteNfcTagUseCase writeUC;
  final DeleteDeviceUseCase deleteUC;
  final UpdateDeviceUseCase updateUC;
  final AppLocalizations loc;

  const _DeviceAdminActions({
    required this.device,
    required this.gymId,
    required this.muscleGroups,
    required this.onUpdated,
    required this.onDeleted,
    required this.writeUC,
    required this.deleteUC,
    required this.updateUC,
    required this.loc,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) async {
        if (value == 'edit') {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (ctx) => DeviceFormDialog(
              initialDevice: device,
              muscleGroups: muscleGroups,
              onSave: (name, description, isMulti, muscleGroupIds, mId, mName) async {
                final updatedDevice = device.copyWith(
                  name: name,
                  description: description,
                  isMulti: isMulti,
                  manufacturerId: mId,
                  manufacturerName: mName,
                  muscleGroupIds: muscleGroupIds,
                );
                
                await updateUC.execute(
                  gymId: gymId,
                  device: updatedDevice,
                );

                final muscleProv = ref.read(muscleGroupProvider);
                await muscleProv.updateDeviceAssignments(
                  context,
                  device.uid,
                  isMulti ? [] : muscleGroupIds,
                  [],
                );
                
                onUpdated();
              },
            ),
          );
        } else if (value == 'nfc' && device.nfcCode != null) {
          try {
            await writeUC.execute(device.nfcCode!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.adminDeviceNfcWritten)),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.adminDeviceNfcWriteError(e.toString()))),
            );
          }
        } else if (value == 'delete') {
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

          final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
          if (fbUser != null) await fbUser.getIdToken(true);

          await deleteUC.execute(gymId: gymId, deviceId: device.uid);
          onDeleted();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.deviceDeleteSuccess)),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 12),
              Text(loc.noteEditTooltip),
            ],
          ),
        ),
        if (device.nfcCode != null)
          PopupMenuItem(
            value: 'nfc',
            child: Row(
              children: [
                const Icon(Icons.nfc, size: 20),
                const SizedBox(width: 12),
                Text(loc.deviceWriteNfcTooltip),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text(
                loc.commonDelete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
