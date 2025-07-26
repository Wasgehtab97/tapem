// lib/features/device/presentation/screens/exercise_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import '../widgets/muscle_group_card.dart';

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
  final List<String> _selectedGroups = [];

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
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final g in groups)
                                    MuscleGroupCard(
                                      name: g.name,
                                      selected: _selectedGroups.contains(g.id),
                                      primary: _selectedGroups.contains(g.id) &&
                                          _selectedGroups.indexOf(g.id) == 0,
                                      onTap: () => setSt(() {
                                        if (_selectedGroups.contains(g.id)) {
                                          _selectedGroups.remove(g.id);
                                        } else {
                                          _selectedGroups.add(g.id);
                                        }
                                      }),
                                    ),
                                ],
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
                          if (name.isNotEmpty && _selectedGroups.isNotEmpty) {
                            final ex = await prov.addExercise(
                              widget.gymId,
                              widget.deviceId,
                              name,
                              userId,
                              muscleGroupIds: List.from(_selectedGroups),
                            );
                            await context.read<MuscleGroupProvider>().assignExercise(
                                  context,
                                  ex.id,
                                  List.from(_selectedGroups),
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
