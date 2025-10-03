import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../../../core/providers/challenge_provider.dart';

class ActiveChallengesWidget extends StatelessWidget {
  const ActiveChallengesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = context.watch<ChallengeProvider>().challenges;
    final loc = AppLocalizations.of(context)!;
    if (challenges.isEmpty) {
      return Center(child: Text(loc.challengeEmptyActive));
    }
    return ListView.builder(
      itemCount: challenges.length,
      itemBuilder: (_, i) {
        final c = challenges[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(c.title),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: Text(c.title),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.description),
                          const SizedBox(height: 8),
                          Text(loc.challengeDetailXpReward(c.xpReward)),
                          const SizedBox(height: 8),
                          Text(loc.challengeDetailDevices(c.deviceIds.join(', '))),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.commonOk),
                        ),
                      ],
                    ),
              );
            },
          ),
        );
      },
    );
  }
}
