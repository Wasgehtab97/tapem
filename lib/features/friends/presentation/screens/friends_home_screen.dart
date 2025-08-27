import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../providers/friends_provider.dart';
import '../../providers/friend_search_provider.dart';
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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<FriendsProvider>().markIncomingSeen();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FriendsProvider>();
    final searchProv = context.watch<FriendSearchProvider>();
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.friends_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.friends_tab_my_friends),
            Tab(text: loc.friends_tab_requests),
            Tab(text: loc.friends_tab_search),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _friendsTab(prov, loc),
          _requestsTab(prov, loc),
          _searchTab(prov, searchProv, loc),
        ],
      ),
    );
  }

  Widget _friendsTab(FriendsProvider prov, AppLocalizations loc) {
    if (prov.friends.isEmpty) {
      return Center(child: Text(loc.friends_empty_friends));
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

  Widget _requestsTab(FriendsProvider prov, AppLocalizations loc) {
    return Column(
      children: [
        Expanded(
          child: prov.incomingPending.isEmpty
              ? Center(child: Text(loc.friends_empty_incoming))
              : ListView.builder(
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
                            onPressed: () async {
                              await prov.accept(r.requestId, r.toUserId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_accepted)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () async {
                              await prov.decline(r.requestId, r.toUserId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_declined)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(),
        Expanded(
          child: prov.outgoingPending.isEmpty
              ? Center(child: Text(loc.friends_empty_outgoing))
              : ListView.builder(
                  itemCount: prov.outgoingPending.length,
                  itemBuilder: (_, i) {
                    final r = prov.outgoingPending[i];
                    return ListTile(
                      title: Text(r.toUserId),
                      subtitle: Text(r.message ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () async {
                          await prov.cancel(r.requestId, r.toUserId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.friends_snackbar_canceled)),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _searchTab(
      FriendsProvider prov, FriendSearchProvider searchProv, AppLocalizations loc) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) =>
                context.read<FriendSearchProvider>().updateQuery(v),
            decoration: InputDecoration(labelText: loc.friends_tab_search),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (_) {
              if (searchProv.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_searchCtrl.text.trim().length < 2) {
                return Center(child: Text(loc.friends_search_min_chars));
              }
              if (searchProv.error != null) {
                return Center(child: Text(searchProv.error!));
              }
              if (searchProv.results.isEmpty) {
                return Center(child: Text(loc.friends_empty_search));
              }
              return ListView.builder(
                itemCount: searchProv.results.length,
                itemBuilder: (_, i) {
                  final p = searchProv.results[i];
                  Widget trailing;
                  if (prov.isSelf(p.uid)) {
                    trailing = Text(loc.friends_cta_self);
                  } else if (prov.isFriend(p.uid)) {
                    trailing = Text(loc.friends_cta_friend);
                  } else if (prov.isOutgoing(p.uid)) {
                    trailing = Text(loc.friends_cta_pending);
                  } else {
                    trailing = TextButton(
                      onPressed: () async {
                        try {
                          await prov.sendRequest(p.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.friends_snackbar_sent)),
                          );
                        } catch (_) {
                          final msg = prov.error ?? 'Error';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      },
                      child: Text(loc.friends_action_send),
                    );
                  }
                  return ListTile(
                    leading: p.avatarUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(p.avatarUrl!),
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(p.username),
                    subtitle: p.primaryGymCode != null
                        ? Text(p.primaryGymCode!)
                        : null,
                    trailing: trailing,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
