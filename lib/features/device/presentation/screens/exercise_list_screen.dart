import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../widgets/multi_device_banner.dart';
import '../widgets/muscle_chips.dart';
import '../widgets/exercise_bottom_sheet.dart';

class ExerciseListScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;

  const ExerciseListScreen({super.key, required this.gymId, required this.deviceId});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final _searchCtr = TextEditingController();
  String _query = '';
  String? _groupFilter;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises(widget.gymId, widget.deviceId, userId);
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  Future<void> _openAdd([Exercise? ex]) async {
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExerciseBottomSheet(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exercise: ex,
      ),
    );
    if (result != null && ex == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRouter.device,
        arguments: {
          'gymId': widget.gymId,
          'deviceId': widget.deviceId,
          'exerciseId': result.id,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prov = context.watch<ExerciseProvider>();
    final groups = context.watch<MuscleGroupProvider>().groups;

    List<Exercise> exercises = prov.exercises.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(_query.toLowerCase());
      final matchesGroup = _groupFilter == null || e.muscleGroupIds.contains(_groupFilter);
      return matchesQuery && matchesGroup;
    }).toList();

    Widget body;
    if (prov.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = Center(child: Text('Fehler: ${prov.error}'));
    } else if (exercises.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.multiDeviceNoExercises),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _openAdd(),
              child: Text(loc.multiDeviceNewExercise),
            ),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (_, i) {
          final ex = exercises[i];
          return ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(ex.name),
            subtitle: MuscleChips(
              primaryIds: ex.muscleGroupIds,
              secondaryIds: const [],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRouter.device,
                arguments: {
                  'gymId': widget.gymId,
                  'deviceId': widget.deviceId,
                  'exerciseId': ex.id,
                },
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openAdd(ex),
              tooltip: loc.multiDeviceEditExerciseButton,
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.multiDeviceExerciseListTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        tooltip: loc.multiDeviceNewExercise,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const MultiDeviceBanner(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtr,
              decoration: InputDecoration(
                hintText: loc.multiDeviceSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String?>(
              value: _groupFilter,
              hint: Text(loc.multiDeviceMuscleGroupFilter),
              isExpanded: true,
              onChanged: (v) => setState(() => _groupFilter = v),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(loc.multiDeviceMuscleGroupFilterAll),
                ),
                for (final g in groups)
                  DropdownMenuItem<String?>(value: g.id, child: Text(g.name)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
    );
  }
}
