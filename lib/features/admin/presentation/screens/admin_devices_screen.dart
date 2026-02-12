import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_empty_state.dart';
import 'package:tapem/core/widgets/app_chip.dart';
import 'package:tapem/core/widgets/app_loading_view.dart';
import 'package:tapem/features/admin/presentation/widgets/device_form_dialog.dart';
import 'package:tapem/features/admin/presentation/widgets/device_list_item.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/update_device_usecase.dart'; // NEW
import 'package:tapem/features/device/providers/device_riverpod.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class AdminDevicesScreen extends ConsumerStatefulWidget {
  const AdminDevicesScreen({super.key});

  @override
  ConsumerState<AdminDevicesScreen> createState() => _AdminDevicesScreenState();
}

class _AdminDevicesScreenState extends ConsumerState<AdminDevicesScreen> {
  static const Set<MuscleRegion> _allowedMuscleRegions = {
    MuscleRegion.brust,
    MuscleRegion.ruecken,
    MuscleRegion.nacken,
    MuscleRegion.schulter,
    MuscleRegion.bizeps,
    MuscleRegion.trizeps,
    MuscleRegion.bauch,
    MuscleRegion.quadrizeps,
    MuscleRegion.hamstrings,
    MuscleRegion.gluteus,
    MuscleRegion.waden,
  };

  late final CreateDeviceUseCase _createUC;
  late final UpdateDeviceUseCase _updateUC; // NEW
  late final GetDevicesForGym _getUC;
  bool _dependenciesLoaded = false;

  final _uuid = const Uuid();
  List<Device> _devices = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesLoaded) {
      final container = ProviderScope.containerOf(context, listen: false);
      _createUC = container.read(createDeviceUseCaseProvider);
      _updateUC = container.read(updateDeviceUseCaseProvider); // NEW
      _getUC = container.read(getDevicesForGymProvider);
      _loadDevices();
      _dependenciesLoaded = true;
    }
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final gymId = ref.read(authControllerProvider).gymCode;
    if (gymId == null) {
      if (!mounted) return;
      setState(() {
        _devices = const [];
        _loading = false;
      });
      return;
    }
    final devices = await _getUC.execute(gymId);
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _loading = false;
    });
  }

  List<MuscleGroup> _resolveAllowedGroups(MuscleGroupProvider muscleProv) {
    final canonicalByRegion = <MuscleRegion, MuscleGroup>{};
    for (final group in muscleProv.groups) {
      if (!_allowedMuscleRegions.contains(group.region)) continue;
      final canonicalName = group.name.trim().toLowerCase();
      if (canonicalName != group.region.name.toLowerCase()) continue;
      canonicalByRegion.putIfAbsent(group.region, () => group);
    }
    final result = canonicalByRegion.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  void _showCreateDialog() {
    final loc = AppLocalizations.of(context)!;
    final gymId = ref.read(authControllerProvider).gymCode;
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidGymSelectionError)),
      );
      return;
    }

    final newUid = _uuid.v4();
    final newId =
        _devices.isEmpty ? 1 : _devices.map((d) => d.id).reduce(max) + 1;
    final muscleProv = ref.read(muscleGroupProvider);
    muscleProv.loadGroups(context);

    // Wait for groups to load if needed (optional optimization)
    // For now we just pass what we resolved
    final allowedGroups = _resolveAllowedGroups(muscleProv);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => DeviceFormDialog(
        nextDeviceId: newId,
        muscleGroups: allowedGroups,
        onSave: (name, description, isMulti, muscleGroupIds, manufacturerId, manufacturerName) async {
             final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
             if (fbUser != null) {
               await fbUser.getIdToken(true);
             }

             final device = Device(
                uid: newUid,
                id: newId,
                name: name,
                description: description,
                isMulti: isMulti,
                manufacturerId: manufacturerId,
                manufacturerName: manufacturerName,
                muscleGroupIds: muscleGroupIds,
              );
              await _createUC.execute(
                gymId: gymId,
                device: device,
                isMulti: isMulti,
                muscleGroupIds: muscleGroupIds,
              );
              await muscleProv.assignDevice(
                context,
                newUid,
                muscleGroupIds,
              );
              await _loadDevices();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: brandColor,
        title: Text(loc.challengeAdminFieldDevices), // "Geräte"
        actions: [
          IconButton(
            icon: const Icon(Icons.factory_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRouter.manageManufacturers),
            tooltip: 'Hersteller verwalten',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: loc.adminDashboardCreateDevice,
          ),
        ],
      ),
      body: SafeArea(
          child: _loading
              ? const AppLoadingView(
                  message: 'Lade Geräte...',
                )
              : _devices.isEmpty
                  ? AppEmptyState(
                      icon: Icons.fitness_center_outlined,
                      message: loc.gymNoDevices,
                      actionLabel: loc.adminDashboardCreateDevice,
                      onAction: _showCreateDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDevices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: DeviceListItem(
                              device: device,
                              onDeleted: _loadDevices,
                              onUpdated: _loadDevices, // NEW
                              muscleGroups: _resolveAllowedGroups(ref.read(muscleGroupProvider)), // NEW
                            ),
                          );
                        },
                      ),
                    ),
        ),
    );
  }
}
