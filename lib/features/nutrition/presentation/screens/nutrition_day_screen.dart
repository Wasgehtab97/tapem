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
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QuickIconButton(
                  tooltip: loc.nutritionAddEntryCta,
                  icon: Icons.search,
                  onTap: () => _openEntry(),
                ),
                const SizedBox(width: AppSpacing.md),
                _QuickIconButton(
                  tooltip: loc.nutritionScanCta,
                  icon: Icons.qr_code_scanner,
                  onTap: () async {
                    final meal = await _pickMeal(context);
                    if (meal == null || !mounted) return;
                    Navigator.of(context).pushNamed(
                      AppRouter.nutritionScan,
                      arguments: {'meal': meal},
                    );
                  },
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
                                    if ((e.$1.qty ?? 0) > 0)
                                      MacroPill(
                                        label: 'Menge',
                                        value:
                                            '${(e.$1.qty ?? 0).toStringAsFixed(0)} g',
                                        color: theme.colorScheme.outline,
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

/// Premium calorie ring with brand gradient and glow
class _CalorieRing extends StatelessWidget {
  final double total;
  final double goal;

  const _CalorieRing({
    required this.total,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final gradient = brand?.gradient ?? AppGradients.brandGradient;
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    // Premium styling matching NutritionHomeScreen
    final progress = goal > 0 ? (total / goal).clamp(0.0, 2.0) : 0.0;
    final isOnTarget = progress >= 1.0;

    // Use improved painter from home screen logic (inline here for simplicity or shared)
    // We'll reimplement the painter here to ensure it matches the premium look exactly
    return CustomPaint(
      painter: _DayCalorieRingPainter(
        progress: progress,
        brandColor: brandColor,
        isOnTarget: isOnTarget,
      ),
    );
  }
}

class _DayCalorieRingPainter extends CustomPainter {
  final double progress;
  final Color brandColor;
  final bool isOnTarget;

  _DayCalorieRingPainter({
    required this.progress,
    required this.brandColor,
    required this.isOnTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeWidth = 14.0;

    // 1. Background track (subtle)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = brandColor.withOpacity(0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 2. Main progress arc
    // Mint -> Turquoise -> Amber brand gradient
    final gradientColors = [
      AppColors.accentMint,
      AppColors.accentTurquoise,
      if (progress > 1.0) AppColors.accentAmber,
    ];
    
    // Adjust colors based on progress overflow
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: gradientColors,
        stops: progress > 1.0 ? [0.0, 0.6, 1.0] : null,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw main arc
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      sweep,
    );

    // 3. Overflow arc (if any)
    if (progress > 1.0) {
      final overflowAngle = 2 * math.pi * (progress - 1.0).clamp(0.0, 1.0);
      final overflowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentAmber
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        overflowAngle,
        false,
        overflowPaint,
      );
      
      // Draw overflow again without blur for sharpness
      overflowPaint.maskFilter = null;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        overflowAngle,
        false,
        overflowPaint,
      );
    }

    // 4. Glow tip
    if (isOnTarget || progress > 0) {
      final angle = -math.pi / 2 + (2 * math.pi * progress).clamp(0.0, 2 * math.pi);
      final tipCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawCircle(
        tipCenter,
        strokeWidth / 1.5,
        Paint()
          ..color = (progress > 1.0 ? AppColors.accentAmber : AppColors.accentTurquoise).withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
       canvas.drawCircle(
        tipCenter,
        strokeWidth / 2.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayCalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.brandColor != brandColor;
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
    
    // Premium Hero Card
    return HeroGradientCard(
      child: Row(
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final box = math.min(constraints.maxWidth, constraints.maxHeight);
                final pctFontSize = (box * 0.18).clamp(12, 22).toDouble();
                final pct = goal > 0 ? (total / goal * 100).clamp(0, 999) : 0;
                final isOver = pct > 100;
                final color = isOver ? AppColors.accentAmber : AppColors.accentMint;
                final text = '${pct.round()}%';
                
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: _CalorieRing(
                        total: total.toDouble(),
                        goal: goal.toDouble(),
                      ),
                    ),
                    BrandGradientText(
                      text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: pctFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandGradientText(
                  dateLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ziel: $goal kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Gesamt: $total kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Freie kcal: $remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: remaining >= 0 ? AppColors.accentMint : AppColors.accentAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MacroPill(
                        label: 'P',
                        value: '$protein g',
                        color: AppColors.accentMint,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: MacroPill(
                        label: 'C',
                        value: '$carbs g',
                        color: AppColors.accentTurquoise,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: MacroPill(
                        label: 'F',
                        value: '$fat g',
                        color: AppColors.accentAmber,
                      ),
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

class _QuickIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final outline = brand?.outline ?? theme.colorScheme.primary;
    final bg = theme.colorScheme.surface.withOpacity(0.22);
    final gradient = LinearGradient(
      colors: [
        outline.withOpacity(0.35),
        outline.withOpacity(0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: gradient,
            border: Border.all(color: outline.withOpacity(0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: outline.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled expansion tile for meals
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
  bool _open = true; // Default open for better visibility

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = widget.totals;
    
    // Premium glassmorphism card
    return BrandInteractiveCard(
      padding: EdgeInsets.zero,
      enableScaleAnimation: false, // Handle interactivity manually
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Meal icon/title
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _open ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totals != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${totals.kcal} kcal · ${totals.protein}g P · ${totals.carbs}g C · ${totals.fat}g F',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: Column(
                children: widget.children,
              ),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

