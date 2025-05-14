// lib/presentation/screens/rank/rank_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/rank/rank_bloc.dart';
import 'package:tapem/presentation/blocs/rank/rank_event.dart';
import 'package:tapem/presentation/blocs/rank/rank_state.dart';
import 'package:tapem/presentation/widgets/rank/exp_badge.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({Key? key}) : super(key: key);

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RankBloc>().add(RankLoadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rangliste'),
      ),
      body: BlocBuilder<RankBloc, RankState>(
        builder: (context, state) {
          if (state is RankLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RankLoadSuccess) {
            final users = state.users;
            if (users.isEmpty) {
              return const Center(child: Text('Keine Nutzer gefunden.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                // Berechne DivisionIndex & expProgress aus totalExperience
                final divisionSize = 1000;
                final divIndex = (user.totalExperience ~/ divisionSize)
                    .clamp(0, 11);
                final progress =
                    user.totalExperience % divisionSize;
                return ListTile(
                  leading: ExpBadge(
                    expProgress: progress,
                    divisionIndex: divIndex,
                    onPressed: () {
                      // z.B. Detailansicht des Nutzers
                    },
                  ),
                  title: Text(user.displayName),
                  subtitle: Text('EXP: ${user.totalExperience}'),
                  trailing: Text('Streak: ${user.currentStreak}'),
                );
              },
            );
          }
          if (state is RankFailure) {
            return Center(child: Text('Fehler: ${state.message}'));
          }
          // RankInitial
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
