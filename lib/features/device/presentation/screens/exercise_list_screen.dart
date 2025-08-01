// lib/features/device/presentation/screens/exercise_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';

class ExerciseListScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  const ExerciseListScreen({
    Key? key,
    required this.gymId,
    required this.deviceId,
  }) : super(key: key);

  @override
  _ExerciseListScreenState createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final _nameCtr = TextEditingController();
  final Set<String> _selectedGroups = {};

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises(
        widget.gymId,
        widget.deviceId,
        userId,
      );
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userId!;
    return Scaffold(
      appBar: AppBar(title: const Text('Übung wählen')),
      body: Consumer<ExerciseProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.error != null) return Center(child: Text('Fehler: ${prov.error}'));
          return ListView(
            children: [
              for (var ex in prov.exercises)
                ListTile(
                  title: Text(ex.name),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRouter.device,
                    arguments: {
                      'gymId': widget.gymId,
                      'deviceId': widget.deviceId,
                      'exerciseId': ex.id,
                    },
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Neue Übung'),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Übung hinzufügen'),
                    content: StatefulBuilder(
                      builder: (ctx2, setSt) {
                        final groups =
                            context.read<MuscleGroupProvider>().groups;
                        return SizedBox(
                          width: 300,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _nameCtr,
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                              ),
                              const SizedBox(height: 8),
                              const Text('Muskelgruppen',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(
                                height: 150,
                                child: ListView(
                                  children: [
                                    for (final g in groups)
                                      CheckboxListTile(
                                        value: _selectedGroups.contains(g.id),
                                        title: Text(g.name),
                                        onChanged: (v) => setSt(() {
                                          if (v == true) {
                                            _selectedGroups.add(g.id);
                                          } else {
                                            _selectedGroups.remove(g.id);
                                          }
                                        }),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _nameCtr.text.trim();
                          if (name.isNotEmpty) {
                            final ex = await prov.addExercise(
                              widget.gymId,
                              widget.deviceId,
                              name,
                              userId,
                              muscleGroupIds: _selectedGroups.toList(),
                            );
                            await context.read<MuscleGroupProvider>().assignExercise(
                                  context,
                                  ex.id,
                                  _selectedGroups.toList(),
                                );
                            Navigator.pop(context);
                            _selectedGroups.clear();
                            _nameCtr.clear();
                          }
                        },
                        child: const Text('Erstellen'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
