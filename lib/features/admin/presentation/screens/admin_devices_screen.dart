import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/features/admin/presentation/widgets/device_list_item.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class AdminDevicesScreen extends StatefulWidget {
  const AdminDevicesScreen({super.key});

  @override
  State<AdminDevicesScreen> createState() => _AdminDevicesScreenState();
}

class _AdminDevicesScreenState extends State<AdminDevicesScreen> {
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
  late final GetDevicesForGym _getUC;
  bool _dependenciesLoaded = false;

  final _uuid = const Uuid();
  List<Device> _devices = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesLoaded) {
      _createUC = context.read<CreateDeviceUseCase>();
      _getUC = context.read<GetDevicesForGym>();
      _loadDevices();
      _dependenciesLoaded = true;
    }
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final gymId = context.read<AuthProvider>().gymCode;
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
    final gymId = context.read<AuthProvider>().gymCode;
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidGymSelectionError)),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final newUid = _uuid.v4();
    final newId =
        _devices.isEmpty ? 1 : _devices.map((d) => d.id).reduce(max) + 1;
    bool isMulti = false;
    bool isSubmitting = false;
    final muscleProv = context.read<MuscleGroupProvider>();
    muscleProv.loadGroups(context);
    final selectedGroups = <String>{};

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) {
          final theme = Theme.of(ctx2);
          final allowedGroups = _resolveAllowedGroups(muscleProv);
          final surfaceVariant = theme.colorScheme.surfaceVariant.withOpacity(
            theme.brightness == Brightness.dark ? 0.5 : 0.9,
          );

          Future<void> submit() async {
            if (isSubmitting) return;
            final name = nameCtrl.text.trim();
            final description = descCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(ctx2).showSnackBar(
                SnackBar(content: Text(loc.challengeAdminErrorFillAllFields)),
              );
              return;
            }
            setSt(() => isSubmitting = true);

            final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
            if (fbUser != null) {
              await fbUser.getIdToken(true);
            }

            FocusScope.of(ctx2).unfocus();

            try {
              final device = Device(
                uid: newUid,
                id: newId,
                name: name,
                description: description,
                isMulti: isMulti,
              );
              await _createUC.execute(
                gymId: gymId,
                device: device,
                isMulti: isMulti,
                muscleGroupIds: selectedGroups.toList(),
              );
              await muscleProv.assignDevice(
                context,
                newUid,
                selectedGroups.toList(),
              );
              if (Navigator.of(ctx2).canPop()) {
                Navigator.of(ctx2).pop(true);
              } else {
                setSt(() => isSubmitting = false);
              }
              await _loadDevices();
            } catch (e, st) {
              elogError('ADMIN_CREATE_DEVICE_FAILED', e, st);
              setSt(() => isSubmitting = false);
              ScaffoldMessenger.of(ctx2).showSnackBar(
                SnackBar(content: Text(loc.commonSaveError)),
              );
            }
          }

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.adminDashboardCreateDeviceDialogTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  value: isMulti,
                  onChanged: (value) => setSt(() => isMulti = value),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    loc.adminDashboardMultipleExercises,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: loc.multiDeviceNameFieldLabel,
                    filled: true,
                    fillColor: surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descCtrl,
                  textInputAction: TextInputAction.newline,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: loc.commonDescription,
                    filled: true,
                    fillColor: surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  loc.muscleGroupTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (muscleProv.isLoading && allowedGroups.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (allowedGroups.isEmpty)
                  const SizedBox.shrink()
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final group in allowedGroups)
                        FilterChip(
                          label: Text(group.name),
                          selected: selectedGroups.contains(group.id),
                          onSelected: (selected) => setSt(() {
                            if (selected) {
                              selectedGroups.add(group.id);
                            } else {
                              selectedGroups.remove(group.id);
                            }
                          }),
                          backgroundColor: surfaceVariant,
                          selectedColor:
                              theme.colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.onPrimary,
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    loc.adminDashboardDeviceIdLabel(newId),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx2).maybePop(false),
                      child: Text(loc.commonCancel),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: BrandPrimaryButton(
                        onPressed: isSubmitting ? null : submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(loc.commonCreate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.challengeAdminFieldDevices), // "Geräte"
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: brandColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: loc.adminDashboardCreateDevice,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(
                brandColor.withOpacity(0.08),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            loc.gymNoDevices,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          BrandPrimaryButton(
                            onPressed: _showCreateDialog,
                            child: Text(loc.adminDashboardCreateDevice),
                          ),
                        ],
                      ),
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
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
