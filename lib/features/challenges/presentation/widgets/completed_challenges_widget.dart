import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/challenge_provider.dart';

class CompletedChallengesWidget extends StatelessWidget {
  const CompletedChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<ChallengeProvider>().badges;
    if (badges.isEmpty) {
      return const Center(child: Text('Noch keine Badges'));
    }
    return ListView.builder(
      itemCount: badges.length,
      itemBuilder: (_, i) {
        final b = badges[i];
        return ListTile(
          title: Text(b.challengeId),
          subtitle: Text('${b.awardedAt.toLocal()}'),
        );
      },
    );
  }
}
