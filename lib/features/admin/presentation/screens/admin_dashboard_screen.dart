// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/admin/presentation/widgets/device_list_item.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/brand_action_tile.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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

  // UseCases werden nur einmal initialisiert
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
      // Why? didChangeDependencies kann mehrfach aufgerufen werden
      _createUC = context.read<CreateDeviceUseCase>();
      _getUC = context.read<GetDevicesForGym>();
      _loadDevices();
      _dependenciesLoaded = true;
    }
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final gymId = context.read<AuthProvider>().gymCode!;
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
    final gymId = context.read<AuthProvider>().gymCode!;
    final loc = AppLocalizations.of(context)!;
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

            // Token neu laden, damit Custom-Claims aktuell sind
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
    final auth = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context)!;
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.adminAreaTitle)),
        body: Center(child: Text(loc.adminAreaNoPermission)),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.adminDashboardTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _AdminActionGrid(
                        actions: [
                          _AdminAction(
                            icon: Icons.add,
                            title: loc.adminDashboardCreateDevice,
                            onTap: _showCreateDialog,
                          ),
                          _AdminAction(
                            icon: Icons.fitness_center,
                            title: loc.muscleGroupTitle,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.manageMuscleGroups);
                            },
                          ),
                          _AdminAction(
                            icon: Icons.brush,
                            title: loc.adminDashboardBranding,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.branding);
                            },
                          ),
                          _AdminAction(
                            icon: Icons.flag,
                            title: loc.challengeAdminTitle,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.manageChallenges);
                            },
                          ),
                          _AdminAction(
                            icon: Icons.person,
                            title: loc.admin_symbols_title,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.adminSymbols);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        loc.challengeAdminFieldDevices,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_devices.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              theme.brightness == Brightness.dark ? 0.5 : 0.9,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              loc.gymNoDevices,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            final device = _devices[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _devices.length - 1
                                    ? 0
                                    : AppSpacing.sm,
                              ),
                              child: DeviceListItem(
                                device: device,
                                onDeleted: () {
                                  _loadDevices();
                                },
                              ),
                            );
                          },
                          childCount: _devices.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _AdminAction {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AdminAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _AdminActionGrid extends StatelessWidget {
  final List<_AdminAction> actions;

  const _AdminActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final itemWidth = isWide
            ? (constraints.maxWidth - AppSpacing.sm) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: BrandActionTile(
                  leadingIcon: action.icon,
                  title: action.title,
                  onTap: action.onTap,
                  variant: BrandActionTileVariant.outlined,
                  showChevron: false,
                  uiLogEvent: 'ADMIN_CARD_RENDER',
                ),
              ),
          ],
        );
      },
    );
  }
}
