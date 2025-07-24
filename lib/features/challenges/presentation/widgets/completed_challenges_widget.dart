import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/challenge_provider.dart';

class CompletedChallengesWidget extends StatelessWidget {
  const CompletedChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final completed = context.watch<ChallengeProvider>().completed;
    if (completed.isEmpty) {
      return const Center(child: Text('Keine abgeschlossenen Challenges'));
    }
    return ListView.builder(
      itemCount: completed.length,
      itemBuilder: (_, i) {
        final c = completed[i];
        return ListTile(
          title: Text(c.title),
          subtitle: Text('${c.completedAt.toLocal()}'),
        );
      },
    );
  }
}
