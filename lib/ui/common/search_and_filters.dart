import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/ui_mutation_guard.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

enum SortOrder { az, za, recent }

class SearchAndFilters extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQuery;
  final SortOrder sort;
  final ValueChanged<SortOrder> onSort;
  final Set<String> muscleFilterIds;
  final ValueChanged<Set<String>> onMuscleFilter;
  const SearchAndFilters({
    super.key,
    required this.query,
    required this.onQuery,
    required this.sort,
    required this.onSort,
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

  Future<void> _showSortSheet() async {
    final res = await showModalBottomSheet<SortOrder>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('A→Z'),
              onTap: () => Navigator.pop(ctx, SortOrder.az),
            ),
            ListTile(
              title: const Text('Z→A'),
              onTap: () => Navigator.pop(ctx, SortOrder.za),
            ),
          ],
        ),
      ),
    );
    if (res != null) widget.onSort(res);
  }

  Future<void> _showMuscleSheet() async {
    final prov = context.read<MuscleGroupProvider>();
    final groups = prov.groups;
    final selected = Set<String>.from(widget.muscleFilterIds);
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in groups)
                      FilterChip(
                        label: Text(g.name),
                        selected: selected.contains(g.id),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    widget.onMuscleFilter(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onQuery,
          decoration: InputDecoration(
            hintText: loc.multiDeviceSearchHint,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilterChip(
              label: const Text('Name'),
              selected: widget.sort == SortOrder.za,
              onSelected: (_) => _showSortSheet(),
              shape: const StadiumBorder(),
              selectedColor: theme.colorScheme.primaryContainer,
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Muskel'),
              selected: widget.muscleFilterIds.isNotEmpty,
              onSelected: (_) => _showMuscleSheet(),
              shape: const StadiumBorder(),
              selectedColor: theme.colorScheme.primaryContainer,
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Zuletzt'),
              selected: widget.sort == SortOrder.recent,
              onSelected: (v) =>
                  widget.onSort(v ? SortOrder.recent : SortOrder.az),
              shape: const StadiumBorder(),
              selectedColor: theme.colorScheme.primaryContainer,
              showCheckmark: false,
            ),
          ],
        ),
      ],
    );
  }
}

