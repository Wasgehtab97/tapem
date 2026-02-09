import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'search_and_filters.dart' show SortOrder;

class FilterChipsRow extends StatelessWidget {
  final SortOrder sort;
  final ValueChanged<SortOrder> onSort;
  final Set<String> muscleFilterIds;
  final ValueChanged<Set<String>> onMuscleFilter;
  final VoidCallback onReset;

  const FilterChipsRow({
    super.key,
    required this.sort,
    required this.onSort,
    required this.muscleFilterIds,
    required this.onMuscleFilter,
    required this.onReset,
  });

  Future<void> _showSortSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final res = await showModalBottomSheet<SortOrder>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BrandModalSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandModalHeader(
              icon: Icons.sort_by_alpha_rounded,
              accent: brandColor,
              title: 'Sortierung',
              subtitle: 'Wähle die Reihenfolge',
              onClose: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 12),
            BrandModalOptionCard(
              title: 'A→Z',
              subtitle: 'Alphabetisch aufsteigend',
              icon: Icons.arrow_downward_rounded,
              accent: brandColor,
              onTap: () => Navigator.pop(ctx, SortOrder.az),
            ),
            const SizedBox(height: 10),
            BrandModalOptionCard(
              title: 'Z→A',
              subtitle: 'Alphabetisch absteigend',
              icon: Icons.arrow_upward_rounded,
              accent: brandColor,
              onTap: () => Navigator.pop(ctx, SortOrder.za),
            ),
          ],
        ),
      ),
    );
    if (res != null) onSort(res);
  }

  Future<void> _showMuscleSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;
    final container = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    );
    final groups = container.read(muscleGroupProvider).groups;
    final selected = Set<String>.from(muscleFilterIds);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => BrandModalSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandModalHeader(
                icon: Icons.fitness_center_rounded,
                accent: brandColor,
                title: loc.filterMuscleChip,
                subtitle: loc.multiDeviceMuscleGroupFilter,
                onClose: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in groups)
                    FilterChip(
                      label: Text(g.name),
                      selected: selected.contains(g.id),
                      showCheckmark: false,
                      backgroundColor: Colors.white.withOpacity(0.04),
                      selectedColor: brandColor.withOpacity(0.22),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: selected.contains(g.id)
                              ? brandColor.withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      onSelected: (v) {
                        setSt(() {
                          if (v) {
                            selected.add(g.id);
                          } else {
                            selected.remove(g.id);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setSt(() => selected.clear()),
                      child: Text(loc.resetFilters),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 108,
                    child: BrandPrimaryButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(loc.commonOk),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    onMuscleFilter(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        ChoiceChip(
          label: Text(loc.filterNameChip),
          selected: sort == SortOrder.za,
          onSelected: (_) => _showSortSheet(context),
          selectedColor: theme.colorScheme.primaryContainer,
          showCheckmark: false,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(loc.filterMuscleChip),
          selected: muscleFilterIds.isNotEmpty,
          onSelected: (_) => _showMuscleSheet(context),
          selectedColor: theme.colorScheme.primaryContainer,
          showCheckmark: false,
        ),
        const Spacer(),
        SizedBox(
          height: 48,
          child: TextButton(onPressed: onReset, child: Text(loc.resetFilters)),
        ),
      ],
    );
  }
}
