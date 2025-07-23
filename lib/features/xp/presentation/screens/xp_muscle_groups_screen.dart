import 'package:flutter/material.dart';

class XPMuscleGroupsScreen extends StatelessWidget {
  const XPMuscleGroupsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final muscleGroups = <String, int>{
      'chest': 0,
      'back': 0,
      'shoulders': 0,
      'arms': 0,
      'core': 0,
      'legs': 0,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('XP Muskelgruppen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: muscleGroups.entries
            .map(
              (e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value} XP'),
              ),
            )
            .toList(),
      ),
    );
  }
}
