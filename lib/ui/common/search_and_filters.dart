import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/ui_mutation_guard.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_display.dart';

enum SortOrder { az, za, recent }

class SearchAndFilters extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQuery;
  final SortOrder sort;
  final ValueChanged<SortOrder> onSort;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesOnlyChanged;
  final Set<String> muscleFilterIds;
  final ValueChanged<Set<String>> onMuscleFilter;
  const SearchAndFilters({
    super.key,
    required this.query,
    required this.onQuery,
    required this.sort,
    required this.onSort,
    required this.favoritesOnly,
    required this.onFavoritesOnlyChanged,
    required this.muscleFilterIds,
    required this.onMuscleFilter,
  });

  @override
  State<SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<SearchAndFilters> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchAndFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      UiMutationGuard.run(
        screen: 'SearchAndFilters',
        widget: 'SearchAndFilters',
        field: 'query',
        oldValue: _controller.text,
        newValue: widget.query,
        reason: 'didUpdateWidget',
        mutate: () {
          if (mounted) _controller.text = widget.query;
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showMuscleSheet() async {
    final loc = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final prov = container.read(muscleGroupProvider);
    final options = _buildMuscleFilterOptions(prov.groups);
    if (options.isEmpty) return;

    final initialSelection = widget.muscleFilterIds
        .where((id) => options.any((option) => option.id == id))
        .toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MuscleFilterSheet(
        options: options,
        initialSelection: initialSelection,
        confirmLabel: loc.commonOk,
        resetLabel: loc.resetFilters,
        title: loc.filterMuscleChip,
      ),
    );
    if (result != null) {
      widget.onMuscleFilter(result);
    }
  }

  String _favoritesLabel() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code == 'de') {
      return 'Favoriten';
    }
    return 'Favorites';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(isDark ? 0.5 : 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                return TextField(
                  controller: _controller,
                  onChanged: widget.onQuery,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: loc.multiDeviceSearchHint,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor.withOpacity(0.7),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: BrandGradientIcon(Icons.search, size: 24),
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.iconTheme.color?.withOpacity(0.5),
                            ),
                            onPressed: () {
                              _controller.clear();
                              widget.onQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _FilterPill(
                label: loc.filterMuscleChip,
                selected: widget.muscleFilterIds.isNotEmpty,
                onTap: () => _showMuscleSheet(),
              ),
              const SizedBox(width: 12),
              _FilterPill(
                label: loc.filterRecentChip,
                selected: widget.sort == SortOrder.recent,
                onTap: () => widget.onSort(
                  widget.sort == SortOrder.recent
                      ? SortOrder.az
                      : SortOrder.recent,
                ),
              ),
              const SizedBox(width: 12),
              _FilterPill(
                label: _favoritesLabel(),
                selected: widget.favoritesOnly,
                onTap: () =>
                    widget.onFavoritesOnlyChanged(!widget.favoritesOnly),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final activeColor = brandTheme?.outline ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.15)
              : theme.cardColor.withOpacity(isDark ? 0.3 : 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? activeColor.withOpacity(0.6)
                : theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? activeColor
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

List<_MuscleFilterOption> _buildMuscleFilterOptions(List<MuscleGroup> groups) {
  final List<_MuscleFilterOption> options = [];
  for (final region in MuscleRegion.values) {
    final regionGroups = groups.where((g) => g.region == region).toList();
    if (regionGroups.isEmpty) {
      continue;
    }
    final canonical =
        regionGroups.firstWhereOrNull(isCanonicalMuscleGroupName) ??
        regionGroups.first;
    options.add(
      _MuscleFilterOption(
        id: canonical.id,
        label: displayNameForMuscleGroup(region, canonical),
      ),
    );
  }
  return options;
}

class _MuscleFilterOption {
  const _MuscleFilterOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _MuscleFilterSheet extends StatefulWidget {
  const _MuscleFilterSheet({
    required this.options,
    required this.initialSelection,
    required this.title,
    required this.confirmLabel,
    required this.resetLabel,
  });

  final List<_MuscleFilterOption> options;
  final Set<String> initialSelection;
  final String title;
  final String confirmLabel;
  final String resetLabel;

  @override
  State<_MuscleFilterSheet> createState() => _MuscleFilterSheetState();
}

class _MuscleFilterSheetState extends State<_MuscleFilterSheet> {
  late final Set<String> _selection = widget.initialSelection
      .where((id) => widget.options.any((element) => element.id == id))
      .toSet();

  void _toggle(String id) {
    setState(() {
      if (_selection.contains(id)) {
        _selection.remove(id);
      } else {
        _selection.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final colorScheme = theme.colorScheme;
    final options = widget.options;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.padding.bottom + 16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withOpacity(0.96),
              colorScheme.surfaceVariant.withOpacity(0.92),
            ],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: media.size.height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final option in options)
                          _MuscleFilterChip(
                            label: option.label,
                            selected: _selection.contains(option.id),
                            onTap: () => _toggle(option.id),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    TextButton(
                      onPressed: _selection.isEmpty
                          ? null
                          : () => setState(() => _selection.clear()),
                      child: Text(widget.resetLabel),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(Set<String>.from(_selection)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(widget.confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuscleFilterChip extends StatelessWidget {
  const _MuscleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: selected
          ? colorScheme.onPrimary
          : colorScheme.onSurfaceVariant.withOpacity(0.9),
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : colorScheme.surfaceVariant.withOpacity(0.75),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withOpacity(0.8)
                : colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}
