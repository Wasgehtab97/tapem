// lib/features/device/presentation/screens/exercise_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';

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
                    content: TextField(
                      controller: _nameCtr,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
                      ElevatedButton(
                        onPressed: () {
                          final name = _nameCtr.text.trim();
                          if (name.isNotEmpty) {
                            prov.addExercise(widget.gymId, widget.deviceId, name, userId);
                            Navigator.pop(context);
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
