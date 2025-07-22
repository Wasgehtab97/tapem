import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/challenge_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class ChallengeTab extends StatefulWidget {
  const ChallengeTab({Key? key}) : super(key: key);

  @override
  State<ChallengeTab> createState() => _ChallengeTabState();
}

class _ChallengeTabState extends State<ChallengeTab> {
  @override
  void initState() {
    super.initState();
    final prov = context.read<ChallengeProvider>();
    final auth = context.read<AuthProvider>();
    prov.watchChallenges();
    final uid = auth.userId;
    if (uid != null) prov.watchBadges(uid);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChallengeProvider>();
    return ListView(
      children: [
        const ListTile(title: Text('Aktive Challenges')),
        for (final c in prov.challenges)
          ListTile(
            title: Text(c.title),
            subtitle: Text(
                '${c.start.toLocal().toIso8601String().split('T').first} - '
                '${c.end.toLocal().toIso8601String().split('T').first}'),
            trailing: Text('${c.goalXp} XP'),
          ),
        const Divider(),
        const ListTile(title: Text('Badges')),
        for (final b in prov.badges)
          ListTile(
            title: Text(b.challengeId),
            subtitle:
                Text(b.awardedAt.toLocal().toIso8601String().split('T').first),
          ),
      ],
    );
  }
}
