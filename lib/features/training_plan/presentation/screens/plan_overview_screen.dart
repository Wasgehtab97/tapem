import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_primary_button.dart';
import 'plan_editor_screen.dart';
import 'import_plan_screen.dart';

class PlanOverviewScreen extends StatefulWidget {
  const PlanOverviewScreen({super.key});

  @override
  State<PlanOverviewScreen> createState() => _PlanOverviewScreenState();
}

class _PlanOverviewScreenState extends State<PlanOverviewScreen> {
  @override
  void initState() {
    super.initState();
    final gymId = context.read<AuthProvider>().gymCode;
    final userId = context.read<AuthProvider>().userId;
    if (gymId != null && userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TrainingPlanProvider>().loadPlans(gymId, userId);
      });
    }
  }

  Future<void> _reload() async {
    final gymId = context.read<AuthProvider>().gymCode;
    final userId = context.read<AuthProvider>().userId;
    if (gymId != null && userId != null) {
      await context.read<TrainingPlanProvider>().loadPlans(gymId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainingspläne')),
      body: Consumer<TrainingPlanProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(child: Text('Fehler: ${prov.error}'));
          }
          return ListView(
            children: [
              for (var plan in prov.plans)
                ListTile(
                  leading: Checkbox(
                    value: prov.activePlanId == plan.id,
                    onChanged: (_) => prov.setActivePlan(plan.id),
                  ),
                  title: Text(
                    plan.name,
                    style:
                        prov.activePlanId == plan.id
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final gymId = context.read<AuthProvider>().gymCode!;
                      if (value == 'rename') {
                        final newName = await _askRename(context, plan.name);
                        if (newName != null) {
                          await prov.renamePlan(gymId, plan.id, newName);
                        }
                      } else if (value == 'delete') {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          await prov.deletePlan(gymId, plan.id);
                        }
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Umbenennen'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Löschen'),
                          ),
                        ],
                  ),
                  onTap: () async {
                    prov.currentPlan = plan;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlanEditorScreen(),
                      ),
                    );
                    if (context.mounted) await _reload();
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          BrandPrimaryButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const ImportPlanScreen()),
                  )
                  .then((_) => _reload());
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file),
                SizedBox(width: AppSpacing.xs),
                Text('Importieren'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BrandPrimaryButton(
            onPressed: () async {
              final cfg = await _askConfig(context);
              if (cfg != null && context.mounted) {
                final userId = context.read<AuthProvider>().userId!;
                context.read<TrainingPlanProvider>().createNewPlan(
                  cfg.name,
                  userId,
                  weeks: cfg.weeks,
                );
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const PlanEditorScreen(),
                      ),
                    )
                    .then((_) => _reload());
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: AppSpacing.xs),
                Text('Neu'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<_PlanCfg?> _askConfig(BuildContext context) async {
    final nameCtr = TextEditingController();
    final weeksCtr = TextEditingController(text: '4');

    return showDialog<_PlanCfg>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: const Text('Neuer Plan'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtr,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        TextField(
                          controller: weeksCtr,
                          decoration: const InputDecoration(
                            labelText: 'Wochen',
                          ),
                          keyboardType: TextInputType.none,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          autofocus: false,
                          onTap: () => context
                              .read<OverlayNumericKeypadController>()
                              .openFor(weeksCtr, allowDecimal: false),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtr.text.trim().isEmpty) return;
                        Navigator.pop(
                          context,
                          _PlanCfg(
                            nameCtr.text.trim(),
                            int.tryParse(weeksCtr.text) ?? 4,
                          ),
                        );
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<String?> _askRename(BuildContext context, String current) async {
    final ctr = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Plan umbenennen'),
            content: TextField(
              controller: ctr,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                      ctr.text.trim().isEmpty ? null : ctr.text.trim(),
                    ),
                child: const Text('Speichern'),
              ),
            ],
          ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Plan löschen?'),
                content: const Text(
                  'Dieser Vorgang kann nicht rückgängig gemacht werden.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Löschen'),
                  ),
                ],
              ),
        ) ??
        false;
  }
}

class _PlanCfg {
  final String name;
  final int weeks;

  _PlanCfg(this.name, this.weeks);
}
