import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';

class RankScreen extends StatefulWidget {
  final String gymId;
  const RankScreen({Key? key, required this.gymId}) : super(key: key);

  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen>
    with SingleTickerProviderStateMixin {
  late RankProvider _provider;
  late TabController _tabController;
  String _selectedChallenge = 'monthly';

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<RankProvider>(context, listen: false);
    _provider.watch(widget.gymId);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Rank'),
              Tab(text: 'Challenges'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRankTab(),
            _buildChallengesTab(),
          ],
        ),
      ),
    );
  }

  Widget _xpWidget(String title) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title),
    );
  }

  Widget _buildRankTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _xpWidget('XP je Muskelgruppe'),
        const SizedBox(height: 16),
        _xpWidget('XP je Trainingstag'),
        const SizedBox(height: 16),
        _xpWidget('XP je Gerät'),
      ],
    );
  }

  Widget _buildChallengesTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _selectedChallenge = 'monthly'),
              child: const Text('Monthly'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _selectedChallenge = 'weekly'),
              child: const Text('Weekly'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: const [
              ListTile(title: Text('Challenge A')),
              ListTile(title: Text('Challenge B')),
              ListTile(title: Text('Challenge C')),
            ],
          ),
        ),
      ],
    );
  }
}
