import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import 'leaderboard_screen.dart';

class DayXpScreen extends StatefulWidget {
  const DayXpScreen({Key? key}) : super(key: key);

  @override
  State<DayXpScreen> createState() => _DayXpScreenState();
}

class _DayXpScreenState extends State<DayXpScreen> {
  StreamSubscription? _lbSub;
  List<Map<String, dynamic>> _lbEntries = [];

  void _openLeaderboard() {
    final auth = context.read<AuthProvider>();
    final gymId = auth.gymCode ?? '';
    Future<List<LeaderboardEntry>> fetchEntries(XpPeriod period) async {
      if (gymId.isEmpty) return [];
      final fs = FirebaseFirestore.instance;
      final snap = await fs.collection('gyms').doc(gymId).collection('users').get();
      final List<LeaderboardEntry> data = [];
      for (final doc in snap.docs) {
        final uid = doc.id;
        final userDoc = await fs.collection('users').doc(uid).get();
        if (!(userDoc.data()?['showInLeaderboard'] as bool? ?? true)) continue;
        final username = userDoc.data()?['username'] as String? ?? uid;
        final statsDoc = await fs
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('rank')
            .doc('stats')
            .get();
        final xp = statsDoc.data()?['dailyXP'] as int? ?? 0;
        data.add(LeaderboardEntry(userId: uid, username: username, xp: xp));
      }
      return data;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(
          title: 'Rangliste',
          fetchEntries: fetchEntries,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final xpProv = context.read<XpProvider>();
    final uid = auth.userId;
    if (uid != null) {
      xpProv.watchTrainingDays(uid);
      xpProv.watchStatsDailyXp(auth.gymCode ?? '', uid);
      _listenLeaderboard(auth.gymCode ?? '');
    }
  }

  void _listenLeaderboard(String gymId) {
    if (gymId.isEmpty) return;
    final fs = FirebaseFirestore.instance;
    debugPrint('👀 listen leaderboard gymId=$gymId');
    _lbSub = fs
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .snapshots()
        .listen((snap) async {
      debugPrint('📥 leaderboard snapshot users=${snap.docs.length}');
      final List<Map<String, dynamic>> data = [];
      for (final doc in snap.docs) {
        final uid = doc.id;
        final userDoc = await fs.collection('users').doc(uid).get();
        if (!(userDoc.data()?['showInLeaderboard'] as bool? ?? true)) continue;
        final username = userDoc.data()?['username'] as String?;
        final statsDoc = await fs
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('rank')
            .doc('stats')
            .get();
        final xp = statsDoc.data()?['dailyXP'] as int? ?? 0;
        data.add({'userId': uid, 'username': username, 'xp': xp});
      }
      data.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      debugPrint('🏆 leaderboard entries=${data.length}');
      setState(() => _lbEntries = data);
    });
  }

  @override
  void dispose() {
    _lbSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final totalXp = xpProv.statsDailyXp;

    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erfahrung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Rangliste',
            onPressed: _openLeaderboard,
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(auth.userName ?? ''),
            trailing: Text('$totalXp'),
          ),
          const Divider(),
          ..._lbEntries.asMap().entries.take(10).map(
                (e) => ListTile(
                  leading: Text('#${e.key + 1}'),
                  title: Text(e.value['username'] ?? e.value['userId']),
                  trailing: Text('${e.value['xp']} XP'),
                ),
              ),
        ],
      ),
    );
  }
}
