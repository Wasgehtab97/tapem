import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_overview_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import '../../domain/utils/nutrition_dates.dart';

const double _colKcalWidth = 38;
const double _colMacroWidth = 32;
const double _colQtyWidth = 38;
const double _colActionWidth = 44;
const double _colCellGap = 2;

class NutritionDayScreen extends ConsumerStatefulWidget {
  const NutritionDayScreen({super.key});

  @override
  ConsumerState<NutritionDayScreen> createState() => _NutritionDayScreenState();
}

class _NutritionDayScreenState extends ConsumerState<NutritionDayScreen> {
  late PageController _pageController;
  final int _initialPage = 10000;
  final DateTime _baseDate = nutritionStartOfDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
  }

  DateTime _getDateForPage(int page) {
    return _baseDate.add(Duration(days: page - _initialPage));
  }

  int _getPageForDate(DateTime date) {
    final diff = nutritionStartOfDay(date).difference(_baseDate).inDays;
    return _initialPage + diff;
  }

  Future<void> _onPageChanged(int page) async {
    final date = _getDateForPage(page);
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, date);
  }

  Future<void> _openEntry({String? meal}) async {
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRouter.nutritionEntry,
      arguments: {'meal': meal ?? _deriveMealFromTime()},
    );
  }

  String _deriveMealFromTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 19) return 'dinner';
    return 'snack';
  }

  Future<void> _openEdit(NutritionEntry entry, int index) async {
    final product = _productFromEntry(entry);
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRouter.nutritionEntry,
      arguments: {
        'name': entry.name,
        'barcode': entry.barcode,
        'meal': entry.meal,
        'product': product,
        'qty': entry.qty ?? 100,
        'index': index,
      },
    );
  }

  NutritionProduct _productFromEntry(NutritionEntry entry) {
    final grams = (entry.qty ?? 100).clamp(1, 100000).toDouble();
    int per100(int value) => (value * 100 / grams).round();
    return NutritionProduct(
      barcode: entry.barcode ?? 'manual-${entry.name.hashCode}',
      name: entry.name,
      kcalPer100: per100(entry.kcal),
      proteinPer100: per100(entry.protein),
      carbsPer100: per100(entry.carbs),
      fatPer100: per100(entry.fat),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final date = state.selectedDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionDayTitle),
        actions: [
          IconButton(
            tooltip: 'Mehr Funktionen',
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.nutritionHome),
          ),
          IconButton(
            tooltip: loc.nutritionChangeDateCta,
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(date.year - 5, 1, 1),
                lastDate: DateTime(date.year + 5, 12, 31),
              );
              if (picked == null || !mounted) return;

              _pageController.jumpToPage(_getPageForDate(picked));
              // _onPageChanged will be called by PageView
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final pageDate = _getDateForPage(index);
          // Only show content for the selected date to simplify state management with the existing provider
          // Alternatively, we could create a specialized widget for each page that loads its own data.
          // But here, since nutritionProvider holds only one day, we only render the "current" day.
          if (nutritionStartOfDay(pageDate) != nutritionStartOfDay(date)) {
            return const Center(child: CircularProgressIndicator());
          }
          return _DayContentView(
            date: date,
            onOpenEntry: _openEntry,
            onOpenEdit: _openEdit,
            onOpenScan: () async {
              if (!mounted) return;
              Navigator.of(context).pushNamed(
                AppRouter.nutritionScan,
                arguments: {'meal': _deriveMealFromTime()},
              );
            },
            onOpenRecipes: () async {
              if (!mounted) return;
              Navigator.of(context).pushNamed(
                AppRouter.nutritionRecipes,
                arguments: {
                  'meal': _deriveMealFromTime(),
                  'isSelectionMode': true,
                  'date': date,
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DayContentView extends ConsumerWidget {
  final DateTime date;
  final VoidCallback onOpenEntry;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenRecipes;
  final Function(NutritionEntry, int) onOpenEdit;

  const _DayContentView({
    required this.date,
    required this.onOpenEntry,
    required this.onOpenScan,
    required this.onOpenRecipes,
    required this.onOpenEdit,
  });

  String _formatQty(double qty) {
    if (qty % 1 == 0) return qty.toInt().toString();
    return qty.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final theme = Theme.of(context);
    final total = state.log?.total;
    final goal = state.goal;
    final targetKcal = goal?.kcal ?? 0;
    final totalKcal = total?.kcal ?? 0;

    if (state.isLoadingDay) {
      return const Center(child: CircularProgressIndicator());
    }

    final entriesWithIndex = (state.log?.entries ?? [])
        .asMap()
        .entries
        .map((e) => (e.value, e.key))
        .toList();

    Map<String, NutritionTotals> mealTotals = {};
    void addToMeal(String meal, NutritionEntry entry) {
      final current = mealTotals[meal];
      mealTotals[meal] = NutritionTotals(
        kcal: (current?.kcal ?? 0) + entry.kcal,
        protein: (current?.protein ?? 0) + entry.protein,
        carbs: (current?.carbs ?? 0) + entry.carbs,
        fat: (current?.fat ?? 0) + entry.fat,
      );
    }

    for (final e in entriesWithIndex) {
      addToMeal(e.$1.meal, e.$1);
    }

    final mealOrder = [
      ('breakfast', 'Frühstück'),
      ('lunch', 'Mittagessen'),
      ('dinner', 'Abendessen'),
      ('snack', 'Snack'),
      ('unspecified', 'Sonstiges'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.lg,
        ),
        children: [
          NutritionOverviewCard(
            date: date,
            goal: targetKcal,
            total: totalKcal,
            protein: state.log?.total.protein ?? 0,
            carbs: state.log?.total.carbs ?? 0,
            fat: state.log?.total.fat ?? 0,
          ),
          const SizedBox(height: AppSpacing.xs),
          _QuickActionStrip(
            actions: [
              _QuickActionData(
                tooltip: loc.nutritionAddEntryCta,
                icon: Icons.search_rounded,
                label: 'Suche',
                onTap: onOpenEntry,
              ),
              _QuickActionData(
                tooltip: loc.nutritionScanCta,
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                onTap: onOpenScan,
              ),
              _QuickActionData(
                tooltip: 'Gerichte auswählen',
                icon: Icons.restaurant_menu_rounded,
                label: 'Gerichte',
                onTap: onOpenRecipes,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (entriesWithIndex.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                loc.nutritionEmptyEntries,
                style: theme.textTheme.bodyMedium,
              ),
            )
          else ...[
            for (final meal in mealOrder)
              if (entriesWithIndex.any((e) => e.$1.meal == meal.$1)) ...[
                _MealExpansion(
                  title: meal.$2,
                  totals: mealTotals[meal.$1],
                  entryCount: entriesWithIndex
                      .where((e) => e.$1.meal == meal.$1)
                      .length,
                  children: entriesWithIndex
                      .where((e) => e.$1.meal == meal.$1)
                      .map(
                        (e) => _MealEntryRow(
                          entry: e.$1,
                          qtyText: _formatQty(e.$1.qty ?? 0),
                          onDelete: () async {
                            final auth = ref.read(authControllerProvider);
                            final uid = auth.userId;
                            if (uid == null) return;
                            await ref.read(nutritionProvider).removeEntry(
                                  uid: uid,
                                  date: date,
                                  index: e.$2,
                                );
                          },
                          onEdit: () => onOpenEdit(e.$1, e.$2),
                        ),
                      )
                      .toList(),
                ),
              ],
          ],
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickActionStrip extends StatelessWidget {
  final List<_QuickActionData> actions;

  const _QuickActionStrip({required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.primary;

    return BrandInteractiveCard(
      padding: EdgeInsets.zero,
      showShadow: false,
      enableScaleAnimation: false,
      showPressedOverlay: false,
      restingBorderColor: Colors.white.withOpacity(0.06),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withOpacity(0.10),
              theme.colorScheme.surface.withOpacity(0.22),
            ],
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(
                child: _QuickActionButton(data: actions[i]),
              ),
              if (i < actions.length - 1)
                Container(
                  width: 1,
                  height: 46,
                  color: Colors.white.withOpacity(0.08),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionButton({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Tooltip(
      message: data.tooltip,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 18, color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onSurface.withOpacity(0.70),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealExpansion extends StatefulWidget {
  final String title;
  final NutritionTotals? totals;
  final int entryCount;
  final List<Widget> children;

  const _MealExpansion({
    required this.title,
    required this.totals,
    required this.entryCount,
    required this.children,
  });

  @override
  State<_MealExpansion> createState() => _MealExpansionState();
}

class _MealExpansionState extends State<_MealExpansion> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.primary;
    final totals = widget.totals;

    final infoText = totals == null
        ? '${widget.entryCount} Einträge'
        : '${widget.entryCount} · ${totals.kcal} kcal · ${totals.protein}P · ${totals.carbs}C · ${totals.fat}F';

    return BrandInteractiveCard(
      padding: EdgeInsets.zero,
      enableScaleAnimation: false,
      showShadow: false,
      showPressedOverlay: false,
      restingBorderColor: Colors.transparent,
      activeBorderColor: Colors.transparent,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.cardLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.25)),
                    ),
                    child: Icon(
                      _open
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          infoText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: accent.withOpacity(0.24)),
                    ),
                    child: Text(
                      '${widget.entryCount}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                10,
                10,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    const _MealTableHeader(),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.onSurface.withOpacity(0.10),
                    ),
                    for (var i = 0; i < widget.children.length; i++) ...[
                      widget.children[i],
                      if (i < widget.children.length - 1)
                        Divider(
                          height: 1,
                          indent: 8,
                          endIndent: 8,
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _MealTableHeader extends StatelessWidget {
  const _MealTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withOpacity(0.55);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Zutat',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _HeaderCell('kcal', width: _colKcalWidth),
          _HeaderCell('P', width: _colMacroWidth),
          _HeaderCell('C', width: _colMacroWidth),
          _HeaderCell('F', width: _colMacroWidth),
          _HeaderCell('g', width: _colQtyWidth),
          const SizedBox(width: _colActionWidth),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;

  const _HeaderCell(this.label, {required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.50),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MealEntryRow extends StatelessWidget {
  final NutritionEntry entry;
  final String qtyText;
  final Future<void> Function() onDelete;
  final VoidCallback onEdit;

  const _MealEntryRow({
    required this.entry,
    required this.qtyText,
    required this.onDelete,
    required this.onEdit,
  });

  Future<void> _handleActionTap(BuildContext context) async {
    final action = await showModalBottomSheet<_EntryAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Bearbeiten'),
                  onTap: () => Navigator.of(sheetContext).pop(_EntryAction.edit),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Löschen',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_EntryAction.delete),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !context.mounted) return;
    if (action == _EntryAction.edit) {
      onEdit();
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Zutat löschen?'),
            content: Text('„${entry.name}“ wirklich entfernen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;
    await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ValueCell(
            width: _colKcalWidth,
            value: '${entry.kcal}',
            color: AppColors.accentTurquoise,
          ),
          _ValueCell(
            width: _colMacroWidth,
            value: '${entry.protein}',
            color: const Color(0xFFE53935),
          ),
          _ValueCell(
            width: _colMacroWidth,
            value: '${entry.carbs}',
            color: AppColors.accentMint,
          ),
          _ValueCell(
            width: _colMacroWidth,
            value: '${entry.fat}',
            color: AppColors.accentAmber,
          ),
          _ValueCell(
            width: _colQtyWidth,
            value: (entry.qty ?? 0) > 0 ? qtyText : '-',
            color: theme.colorScheme.onSurface.withOpacity(0.78),
          ),
          SizedBox(
            width: _colActionWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: _RowActionMenuButton(
                onTap: () => _handleActionTap(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final double width;
  final String value;
  final Color color;

  const _ValueCell({
    required this.width,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      margin: const EdgeInsets.only(left: _colCellGap),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.28), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

enum _EntryAction { edit, delete }

class _RowActionMenuButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RowActionMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withOpacity(0.78);
    return Tooltip(
      message: 'Optionen',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.more_horiz_rounded, size: 18, color: color),
        ),
      ),
    );
  }
}
