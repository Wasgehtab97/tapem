import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_macros.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NutritionGoalsScreen extends ConsumerStatefulWidget {
  const NutritionGoalsScreen({super.key});

  @override
  ConsumerState<NutritionGoalsScreen> createState() =>
      _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends ConsumerState<NutritionGoalsScreen> {
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoal());
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
  }

  void _syncControllers() {
    if (_initialized) return;
    final goal = ref.read(nutritionProvider).goal;
    _kcalController.text = (goal?.kcal ?? 0).toString();
    _proteinController.text = (goal?.macros.protein ?? 0).toString();
    _carbsController.text = (goal?.macros.carbs ?? 0).toString();
    _fatController.text = (goal?.macros.fat ?? 0).toString();
    _initialized = true;
  }

  int _parseInt(String raw) {
    final sanitized = raw.trim();
    if (sanitized.isEmpty) return 0;
    return int.tryParse(sanitized) ?? 0;
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
            kcal: _parseInt(_kcalController.text),
            macros: NutritionMacros(
              protein: _parseInt(_proteinController.text),
              carbs: _parseInt(_carbsController.text),
              fat: _parseInt(_fatController.text),
            ),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    _syncControllers();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionGoalsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            loc.nutritionGoalsIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _GoalField(
            label: loc.nutritionGoalsCaloriesLabel,
            controller: _kcalController,
          ),
          const SizedBox(height: 12),
          _GoalField(
            label: loc.nutritionGoalsProteinLabel,
            controller: _proteinController,
          ),
          const SizedBox(height: 12),
          _GoalField(
            label: loc.nutritionGoalsCarbsLabel,
            controller: _carbsController,
          ),
          const SizedBox(height: 12),
          _GoalField(
            label: loc.nutritionGoalsFatLabel,
            controller: _fatController,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _saveGoals,
            child: Text(loc.nutritionGoalsSaveCta),
          ),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _GoalField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
