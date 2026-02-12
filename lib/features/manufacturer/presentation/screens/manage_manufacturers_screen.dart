import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_loading_view.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/features/manufacturer/domain/models/manufacturer.dart';
import 'package:tapem/features/manufacturer/providers/manufacturer_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ManageManufacturersScreen extends ConsumerStatefulWidget {
  const ManageManufacturersScreen({super.key});

  @override
  ConsumerState<ManageManufacturersScreen> createState() => _ManageManufacturersScreenState();
}

class _ManageManufacturersScreenState extends ConsumerState<ManageManufacturersScreen> {
  @override
  void initState() {
    super.initState();
    // Seed global manufacturers if empty (admin convenience for now)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seedGlobalManufacturersProvider)();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymManufacturersAsync = ref.watch(gymManufacturersProvider);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hersteller verwalten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openAddDialog(context, accent),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.95),
                theme.colorScheme.background,
              ]),
        ),
        child: gymManufacturersAsync.when(
          loading: () => const AppLoadingView(message: 'Lade Hersteller...'),
          error: (err, st) => Center(child: Text('Fehler: $err')),
          data: (manufacturers) {
            if (manufacturers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.factory_outlined, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Hersteller aktiviert',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    BrandPrimaryButton(
                      onPressed: () => _openAddDialog(context, accent),
                      child: const Text('Hersteller hinzufügen'),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: manufacturers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final manufacturer = manufacturers[index];
                return BrandModalOptionCard(
                  title: manufacturer.name,
                  subtitle: manufacturer.isGlobal ? 'Globaler Hersteller' : 'Individueller Hersteller',
                  icon: Icons.business_rounded,
                  accent: accent,
                  onTap: () {}, // Maybe edit later
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () => _removeManufacturer(manufacturer),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openAddDialog(BuildContext context, Color accent) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AddManufacturerDialog(accent: accent),
    );
  }

  Future<void> _removeManufacturer(Manufacturer manufacturer) async {
    final gymId = ref.read(authControllerProvider).gymCode;
    if (gymId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hersteller entfernen?'),
        content: Text('Möchtest du "${manufacturer.name}" wirklich entfernen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(manufacturerRepositoryProvider).removeManufacturerFromGym(gymId, manufacturer.id);
      ref.refresh(gymManufacturersProvider);
    }
  }
}

class _AddManufacturerDialog extends ConsumerStatefulWidget {
  final Color accent;
  const _AddManufacturerDialog({required this.accent});

  @override
  ConsumerState<_AddManufacturerDialog> createState() => _AddManufacturerDialogState();
}

class _AddManufacturerDialogState extends ConsumerState<_AddManufacturerDialog> {
  // We fetch global list
  // We can filter locally for now since the list is small (15 items)
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final globalManufacturersAsync = ref.watch(globalManufacturersProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: BrandModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandModalHeader(
              title: 'Hersteller hinzufügen',
              subtitle: 'Wähle aus der globalen Liste',
              icon: Icons.add_home_work_rounded, // Better available icon or just domain
              accent: widget.accent,
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
            // Search Field
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Suchen...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: globalManufacturersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Fehler: $err'),
                data: (allData) {
                  final filtered = allData.where((m) => m.name.toLowerCase().contains(_searchQuery)).toList();
                  if (filtered.isEmpty) {
                     // Option to create custom? Maybe later.
                     return const Center(child: Text('Keine Hersteller gefunden.', style: TextStyle(color: Colors.white54)));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final m = filtered[idx];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: Colors.white.withOpacity(0.05),
                        title: Text(m.name, style: const TextStyle(color: Colors.white)),
                        trailing: Icon(Icons.add_circle_outline, color: widget.accent),
                        onTap: () => _add(m),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(Manufacturer m) async {
    final gymId = ref.read(authControllerProvider).gymCode;
    if (gymId == null) return;
    
    // Add to gym
    await ref.read(manufacturerRepositoryProvider).addManufacturerToGym(gymId, m);
    // Refresh local
    ref.refresh(gymManufacturersProvider);
    if (mounted) Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${m.name} aktiviert.')),
    );
  }
}
