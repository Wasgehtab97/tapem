import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';

class XpOverviewScreen extends StatefulWidget {
  const XpOverviewScreen({Key? key}) : super(key: key);

  @override
  State<XpOverviewScreen> createState() => _XpOverviewScreenState();
}

class _XpOverviewScreenState extends State<XpOverviewScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final xpProv = context.read<XpProvider>();
    final uid = auth.userId;
    if (uid != null) {
      xpProv.watchDayXp(uid, DateTime.now());
      xpProv.watchMuscleXp(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final muscleEntries = xpProv.muscleXp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('XP Übersicht')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('XP heute'),
            trailing: Text('${xpProv.dayXp}'),
          ),
          const Divider(),
          ...muscleEntries.map(
            (e) => ListTile(
              title: Text(e.key),
              trailing: Text('${e.value} XP'),
            ),
          ),
        ],
      ),
    );
  }
}
