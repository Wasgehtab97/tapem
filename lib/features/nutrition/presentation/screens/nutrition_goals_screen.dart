import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_macros.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
    final accent = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.cardLg),
                gradient: LinearGradient(
                  colors: [
                    surface.withOpacity(0.8),
                    surface.withOpacity(0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.nutritionGoalsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    loc.nutritionGoalsIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${_initialized ? _kcal : 0} kcal',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _kcalController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: loc.nutritionGoalsCaloriesLabel,
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.replaceAll(RegExp(r'\\D'), ''));
                              if (parsed != null) _setKcal(parsed);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SecondaryCTA(
                              label: '-100',
                              icon: Icons.remove,
                              onPressed: () => _setKcal(_kcal - 100),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            SecondaryCTA(
                              label: '+100',
                              icon: Icons.add,
                              onPressed: () => _setKcal(_kcal + 100),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                          ),
                          child: Slider(
                            value: _kcal.toDouble().clamp(0, 6000),
                            min: 0,
                            max: 6000,
                            divisions: 60,
                            label: '$_kcal kcal',
                            activeColor: accent,
                            onChanged: (v) => _setKcal(v.round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryCTA(
              label: loc.nutritionGoalsSaveCta,
              icon: Icons.check_circle,
              onPressed: _isSaving ? null : _saveGoals,
            ),
          ],
        ),
      ),
    );
  }
}
