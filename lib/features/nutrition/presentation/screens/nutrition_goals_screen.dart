import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_macros.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionGoalsScreen extends ConsumerStatefulWidget {
  const NutritionGoalsScreen({super.key});

  @override
  ConsumerState<NutritionGoalsScreen> createState() =>
      _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends ConsumerState<NutritionGoalsScreen> {
  final TextEditingController _kcalController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;
  int _kcal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoal());
  }

  @override
  void dispose() {
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
    if (!mounted) return;
    final goal = ref.read(nutritionProvider).goal;
    setState(() {
      _kcal = goal?.kcal ?? 0;
      _kcalController.text = _kcal.toString();
      _initialized = true;
    });
  }

  void _setKcal(int value) {
    final clamped = value.clamp(0, 6000);
    setState(() {
      _kcal = clamped;
      _kcalController.text = clamped.toString();
    });
  }

  Future<void> _saveGoals() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(nutritionProvider).saveGoal(
            uid: uid,
            date: DateTime.now(),
            kcal: _kcal,
            macros: const NutritionMacros(protein: 0, carbs: 0, fat: 0),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionGoalsSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionGoalsSaveError)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionGoalsTitle),
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
            // Premium hero card with goal input
            HeroGradientCard(
              enableBackdropBlur: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandGradientText(
                    loc.nutritionGoalsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    loc.nutritionGoalsIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Large animated calorie display
                  Center(
                    child: AnimatedNutritionStat(
                      value: _initialized ? _kcal : 0,
                      label: 'kcal Tagesziel',
                      enableFlicker: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Text input
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: NutritionCard(
                        enableGlow: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: TextField(
                          controller: _kcalController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: brandColor,
                          ),
                          decoration: InputDecoration(
                            labelText: loc.nutritionGoalsCaloriesLabel,
                            border: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val.replaceAll(RegExp(r'\\D'), ''));
                            if (parsed != null) _setKcal(parsed);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Quick adjust buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SecondaryCTA(
                        label: '-100',
                        icon: Icons.remove_rounded,
                        onPressed: () => _setKcal(_kcal - 100),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SecondaryCTA(
                        label: '+100',
                        icon: Icons.add_rounded,
                        onPressed: () => _setKcal(_kcal + 100),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Brand gradient slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: brandColor,
                      inactiveTrackColor: brandColor.withOpacity(0.2),
                      thumbColor: brandColor,
                      overlayColor: brandColor.withOpacity(0.15),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _kcal.toDouble().clamp(0, 6000),
                      min: 0,
                      max: 6000,
                      divisions: 60,
                      label: '$_kcal kcal',
                      onChanged: (v) => _setKcal(v.round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Save button
            PrimaryCTA(
              label: loc.nutritionGoalsSaveCta,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _isSaving ? null : _saveGoals,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
