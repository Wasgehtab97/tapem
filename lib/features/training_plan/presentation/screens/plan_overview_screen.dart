import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final gymId = context.read<AuthProvider>().gymId;
    if (gymId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TrainingPlanProvider>().loadPlans(gymId);
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
              final name = await _askName(context);
              if (name != null && context.mounted) {
                context.read<TrainingPlanProvider>().createNewPlan(name);
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

  Future<String?> _askName(BuildContext context) async {
    final ctr = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Planname'),
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
                onPressed: () => Navigator.pop(context, ctr.text.trim()),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
