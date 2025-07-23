import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/challenge_provider.dart';

class ActiveChallengesWidget extends StatelessWidget {
  const ActiveChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = context.watch<ChallengeProvider>().challenges;
    if (challenges.isEmpty) {
      return const Center(child: Text('Keine aktiven Challenges'));
    }
    return ListView.builder(
      itemCount: challenges.length,
      itemBuilder: (_, i) {
        final c = challenges[i];
        return ListTile(
          title: Text(c.title),
          subtitle: Text(c.description),
        );
      },
    );
  }
}
