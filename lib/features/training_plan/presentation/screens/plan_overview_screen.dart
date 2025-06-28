import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
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
                  title: Text(plan.name),
                  onTap: () {
                    prov.currentPlan = plan;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlanEditorScreen(),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import',
            icon: const Icon(Icons.upload_file),
            label: const Text('Importieren'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportPlanScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new',
            icon: const Icon(Icons.add),
            label: const Text('Neu'),
            onPressed: () async {
              final cfg = await _askConfig(context);
              if (cfg != null && context.mounted) {
                final userId = context.read<AuthProvider>().userId!;
                context.read<TrainingPlanProvider>().createNewPlan(
                  cfg.name,
                  userId,
                  weeks: cfg.weeks,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanEditorScreen()),
                );
              }
            },
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
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
                  decoration: const InputDecoration(labelText: 'Wochen'),
                  keyboardType: TextInputType.number,
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

}

class _PlanCfg {
  final String name;
  final int weeks;

  _PlanCfg(this.name, this.weeks);
}
