import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';

class DayXpScreen extends StatefulWidget {
  const DayXpScreen({Key? key}) : super(key: key);

  @override
  State<DayXpScreen> createState() => _DayXpScreenState();
}

class _DayXpScreenState extends State<DayXpScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final xpProv = context.read<XpProvider>();
    final uid = auth.userId;
    if (uid != null) {
      xpProv.watchTrainingDays(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final entries = xpProv.dayListXp.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Scaffold(
      appBar: AppBar(title: const Text('Trainingstage XP')),
      body: ListView(
        children: entries
            .map((e) => ListTile(
                  title: Text(e.key),
                  trailing: Text('${e.value} XP'),
                ))
            .toList(),
      ),
    );
  }
}
