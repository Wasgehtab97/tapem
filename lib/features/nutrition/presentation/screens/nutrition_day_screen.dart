import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'dart:math' as math;

class NutritionDayScreen extends ConsumerStatefulWidget {
  const NutritionDayScreen({super.key});

  @override
  ConsumerState<NutritionDayScreen> createState() => _NutritionDayScreenState();
}

class _NutritionDayScreenState extends ConsumerState<NutritionDayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  Future<void> _loadToday() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
  }

  Future<void> _openEntry({String? meal}) async {
    String? chosenMeal = meal;
    if (chosenMeal == null) {
      chosenMeal = await _pickMeal(context);
      if (chosenMeal == null) return; // dismissed
    }
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRouter.nutritionEntry,
      arguments: {
        'meal': chosenMeal,
      },
    );
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

  Future<String?> _pickMeal(BuildContext context) async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    String labelFor(String meal) {
      final isDe = Localizations.localeOf(context).languageCode.startsWith('de');
      switch (meal) {
        case 'breakfast':
          return isDe ? 'Frühstück' : 'Breakfast';
        case 'lunch':
          return isDe ? 'Mittagessen' : 'Lunch';
        case 'dinner':
          return isDe ? 'Abendessen' : 'Dinner';
        case 'snack':
          return isDe ? 'Snack' : 'Snack';
        default:
          return meal;
      }
    }
    final meals = [
      ('breakfast', labelFor('breakfast')),
      ('lunch', labelFor('lunch')),
      ('dinner', labelFor('dinner')),
      ('snack', labelFor('snack')),
    ];
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  loc.nutritionAddEntryCta,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (final meal in meals)
                ListTile(
                  title: Text(meal.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).pop(meal.$1),
                ),
            ],
          ),
        );
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
    final dateLabel = DateFormat.yMMMd().format(date);
    final total = state.log?.total;
    final goal = state.goal;
    final targetKcal = goal?.kcal ?? 0;
    final totalKcal = total?.kcal ?? 0;
    final theme = Theme.of(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionDayTitle),
        actions: [
          IconButton(
            tooltip: loc.nutritionChangeDateCta,
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(date.year - 1, 1, 1),
                lastDate: DateTime(date.year + 1, 12, 31),
              );
              if (picked == null || !mounted) return;
              final auth = ref.read(authControllerProvider);
              final uid = auth.userId;
              if (uid == null || uid.isEmpty) return;
              await ref.read(nutritionProvider).loadDay(uid, picked);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          children: [
            NutritionHeaderCard(
              date: date,
              goal: targetKcal,
              total: totalKcal,
              protein: state.log?.total.protein ?? 0,
              carbs: state.log?.total.carbs ?? 0,
              fat: state.log?.total.fat ?? 0,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: loc.nutritionAddEntryCta,
                    icon: Icons.add,
                    onPressed: () => _openEntry(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ActionButton(
                    label: loc.nutritionScanCta,
                    icon: Icons.qr_code_scanner,
                    onPressed: () async {
                      final meal = await _pickMeal(context);
                      if (meal == null || !mounted) return;
                      Navigator.of(context).pushNamed(
                        AppRouter.nutritionScan,
                        arguments: {'meal': meal},
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoadingDay)
              const Center(child: CircularProgressIndicator())
            else if ((state.log?.entries.isEmpty ?? true))
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
                    children: entriesWithIndex
                        .where((e) => e.$1.meal == meal.$1)
                        .map(
                          (e) => NutritionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.$1.name,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final auth =
                                            ref.read(authControllerProvider);
                                        final uid = auth.userId;
                                        if (uid == null) return;
                                        await ref
                                            .read(nutritionProvider)
                                            .removeEntry(
                                              uid: uid,
                                              date: state.selectedDate,
                                              index: e.$2,
                                            );
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                    IconButton(
                                      onPressed: () => _openEdit(e.$1, e.$2),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    MacroPill(
                                      label: 'Kcal',
                                      value: '${e.$1.kcal}',
                                      color: Colors.blueAccent,
                                    ),
                                    MacroPill(
                                      label: 'P',
                                      value: '${e.$1.protein} g',
                                      color: Colors.redAccent,
                                    ),
                                    MacroPill(
                                      label: 'C',
                                      value: '${e.$1.carbs} g',
                                      color: Colors.greenAccent.shade400,
                                    ),
                                    MacroPill(
                                      label: 'F',
                                      value: '${e.$1.fat} g',
                                      color: Colors.amber.shade700,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final double total;
  final double goal;
  final Color trackColor;
  final Color progressStart;
  final Color progressEnd;
  final Color overStart;
  final Color overEnd;

  const _CalorieRing({
    required this.total,
    required this.goal,
    required this.trackColor,
    required this.progressStart,
    required this.progressEnd,
    required this.overStart,
    required this.overEnd,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CalorieRingPainter(
        total: total,
        goal: goal,
        trackColor: trackColor,
        progressStart: progressStart,
        progressEnd: progressEnd,
        overStart: overStart,
        overEnd: overEnd,
      ),
    );
  }
}

class NutritionHeaderCard extends StatelessWidget {
  final DateTime date;
  final int goal;
  final int total;
  final int protein;
  final int carbs;
  final int fat;

  const NutritionHeaderCard({
    super.key,
    required this.date,
    required this.goal,
    required this.total,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMd().format(date);
    final remaining = goal - total;
    final proteinKcal = (protein * 4).toDouble();
    final carbsKcal = (carbs * 4).toDouble();
    final fatKcal = (fat * 9).toDouble();
    final kcalTotal = (proteinKcal + carbsKcal + fatKcal).clamp(1, double.infinity);

    int _segmentFlex(double value) {
      final ratio = (value / kcalTotal) * 1000;
      return ratio.isFinite ? ratio.clamp(1, 1000).round() : 1;
    }

    final proteinFlex = _segmentFlex(proteinKcal);
    final carbsFlex = _segmentFlex(carbsKcal);
    final fatFlex = _segmentFlex(fatKcal);

    final brand = theme.extension<AppBrandTheme>();
    final gradient = brand?.gradient ?? AppGradients.brandGradient;
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final cardGradient = LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors
          .map(
            (c) => Color.lerp(c, theme.scaffoldBackgroundColor, 0.5) ?? c,
          )
          .toList(growable: false),
    );
    final ringBase = brandColor.withOpacity(0.18);
    final ringProgressStart = gradient.colors.first.withOpacity(0.95);
    final ringProgressEnd = gradient.colors.last.withOpacity(0.95);
    final ringOverStart =
        Color.lerp(brandColor, Colors.deepOrangeAccent, 0.35) ??
            Colors.deepOrangeAccent;
    final ringOverEnd = Colors.redAccent.withOpacity(0.95);
    final remainingColor =
        remaining >= 0 ? brandColor : Colors.redAccent.withOpacity(0.9);

    return NutritionCard(
      neutral: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: _CalorieRing(
              total: total.toDouble(),
              goal: goal.toDouble(),
              trackColor: ringBase,
              progressStart: ringProgressStart,
              progressEnd: ringProgressEnd,
              overStart: ringOverStart,
              overEnd: ringOverEnd,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ziel: $goal kcal',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Gesamt: $total kcal',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Freie kcal: $remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: remainingColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    MacroPill(
                      label: 'P',
                      value: '$protein g',
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    MacroPill(
                      label: 'C',
                      value: '$carbs g',
                      color: Colors.greenAccent.shade400,
                    ),
                    const SizedBox(width: 6),
                    MacroPill(
                      label: 'F',
                      value: '$fat g',
                      color: Colors.amber.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double total;
  final double goal;
  final Color trackColor;
  final Color progressStart;
  final Color progressEnd;
  final Color overStart;
  final Color overEnd;

  _CalorieRingPainter({
    required this.total,
    required this.goal,
    required this.trackColor,
    required this.progressStart,
    required this.progressEnd,
    required this.overStart,
    required this.overEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    if (goal <= 0) return;

    final progress = total / goal;
    final firstLap = progress.clamp(0.0, 1.0);
    final secondLap = (progress - 1.0).clamp(0.0, 1.0);
    final fullCircle = 2 * math.pi;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    if (firstLap > 0) {
      arcPaint.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + fullCircle * firstLap,
        colors: [
          Color.lerp(progressStart, progressEnd, 0.3)!,
          Color.lerp(progressStart, progressEnd, firstLap)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        fullCircle * firstLap,
        false,
        arcPaint,
      );
    }

    if (secondLap > 0) {
      arcPaint.shader = SweepGradient(
        startAngle: -math.pi / 2 + fullCircle * firstLap,
        endAngle: -math.pi / 2 + fullCircle * (firstLap + secondLap),
        colors: [
          Color.lerp(overStart, overEnd, 0.2)!,
          Color.lerp(overStart, overEnd, secondLap)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + fullCircle * firstLap,
        fullCircle * secondLap,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.goal != goal;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final scaffold = theme.scaffoldBackgroundColor;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(scaffold, brandColor, 0.08) ?? scaffold,
        Color.lerp(scaffold, Colors.black, 0.02) ?? scaffold,
      ],
    );
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: labelStyle?.copyWith(
                      height: 1.1,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brandColor.withOpacity(0.22),
                        brandColor.withOpacity(0.02),
                      ],
                      center: Alignment.topLeft,
                      radius: 1.0,
                    ),
                    border: Border.all(
                      color: brandColor.withOpacity(0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: brandColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealExpansion extends StatefulWidget {
  final String title;
  final NutritionTotals? totals;
  final List<Widget> children;

  const _MealExpansion({
    required this.title,
    required this.totals,
    required this.children,
  });

  @override
  State<_MealExpansion> createState() => _MealExpansionState();
}

class _MealExpansionState extends State<_MealExpansion> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = widget.totals;
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        if (totals != null)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              MacroPill(
                                label: 'Kcal',
                                value: '${totals.kcal}',
                                color: Colors.blueAccent,
                              ),
                              MacroPill(
                                label: 'P',
                                value: '${totals.protein} g',
                                color: Colors.redAccent,
                              ),
                              MacroPill(
                                label: 'C',
                                value: '${totals.carbs} g',
                                color: Colors.greenAccent.shade400,
                              ),
                              MacroPill(
                                label: 'F',
                                value: '${totals.fat} g',
                                color: Colors.amber.shade700,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: widget.children,
            ),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}
