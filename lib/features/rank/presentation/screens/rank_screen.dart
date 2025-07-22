import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/app_router.dart';

class RankScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  const RankScreen({Key? key, required this.gymId, required this.deviceId})
      : super(key: key);

  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  late RankProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<RankProvider>(context, listen: false);
    _provider.watch(widget.gymId, widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: const Text('XP je Muskelgruppe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRouter.xpOverview),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              title: const Text('XP je Trainingstag'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRouter.dayXp),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: const Text('XP je Gerät'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRouter.deviceXp),
            ),
          ),
          Expanded(
            child: Consumer<RankProvider>(
              builder: (context, prov, _) {
                final entries = prov.entries;
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      leading: Text('#${i + 1}'),
                      title: Text(e['username'] ?? e['userId']),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('L${e['level'] ?? 1}'),
                          Text('${e['xp']} XP'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
