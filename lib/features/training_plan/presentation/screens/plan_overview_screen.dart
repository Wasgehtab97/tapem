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
                  startDate: cfg.startDate,
                  weeks: cfg.weeks,
                  week1Dates: cfg.week1Dates,
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
    final List<DateTime> dates = [];

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
                const SizedBox(height: 8),
                for (var d in dates)
                  Text(DateFormat.yMd().format(d)),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => dates.add(picked));
                    }
                  },
                  child: const Text('Tag hinzufügen'),
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
                if (nameCtr.text.trim().isEmpty || dates.isEmpty) return;
                Navigator.pop(
                  context,
                  _PlanCfg(
                    nameCtr.text.trim(),
                    int.tryParse(weeksCtr.text) ?? 4,
                    dates,
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
  final List<DateTime> week1Dates;
  DateTime get startDate => week1Dates.first;
  _PlanCfg(this.name, this.weeks, this.week1Dates);
}
