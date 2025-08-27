import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friends_provider.dart';
import '../../domain/models/public_profile.dart';
import 'friend_detail_screen.dart';

class FriendsHomeScreen extends StatefulWidget {
  const FriendsHomeScreen({Key? key}) : super(key: key);
  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const FriendsHomeScreen());
  @override
  State<FriendsHomeScreen> createState() => _FriendsHomeScreenState();
}

class _FriendsHomeScreenState extends State<FriendsHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _incomingSeen;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<PublicProfile> _results = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<FriendsProvider>().markIncomingSeen();
      }
    });
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final text = _searchCtrl.text.trim().toLowerCase();
      if (text.length < 2) {
        setState(() => _results = []);
        return;
      }
      final prov = context.read<FriendsProvider>();
      final res = await prov.search(text);
      setState(() => _results = res);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _debounce?.cancel();
    _incomingSeen?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FriendsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freunde'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meine Freunde'),
            Tab(text: 'Anfragen'),
            Tab(text: 'Suchen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _friendsTab(prov),
          _requestsTab(prov),
          _searchTab(prov),
        ],
      ),
    );
  }

  Widget _friendsTab(FriendsProvider prov) {
    if (prov.friends.isEmpty) {
      return const Center(child: Text('Keine Freunde'));
    }
    return ListView.builder(
      itemCount: prov.friends.length,
      itemBuilder: (_, i) {
        final f = prov.friends[i];
        return ListTile(
          title: Text(f.friendUid),
          onTap: () {
            Navigator.push(context, FriendDetailScreen.route(f.friendUid));
          },
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => prov.removeFriend(f.friendUid),
          ),
        );
      },
    );
  }

  Widget _requestsTab(FriendsProvider prov) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: prov.incomingPending.length,
            itemBuilder: (_, i) {
              final r = prov.incomingPending[i];
              return ListTile(
                title: Text(r.fromUserId),
                subtitle: Text(r.message ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => prov.accept(r.requestId, r.toUserId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => prov.decline(r.requestId, r.toUserId),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: prov.outgoingPending.length,
            itemBuilder: (_, i) {
              final r = prov.outgoingPending[i];
              return ListTile(
                title: Text(r.toUserId),
                subtitle: Text(r.message ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => prov.cancel(r.requestId, r.toUserId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchTab(FriendsProvider prov) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(labelText: 'Suche'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) {
              final p = _results[i];
              return ListTile(
                title: Text(p.username),
                subtitle: Text(p.primaryGymCode ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => prov.sendRequest(p.uid),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
