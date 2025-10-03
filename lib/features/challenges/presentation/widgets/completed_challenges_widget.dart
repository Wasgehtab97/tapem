import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../../../core/providers/challenge_provider.dart';

class CompletedChallengesWidget extends StatelessWidget {
  const CompletedChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final completed = context.watch<ChallengeProvider>().completed;
    final loc = AppLocalizations.of(context)!;
    if (completed.isEmpty) {
      return Center(child: Text(loc.challengeEmptyCompleted));
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
