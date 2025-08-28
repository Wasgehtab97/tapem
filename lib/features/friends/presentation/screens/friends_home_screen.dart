import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../providers/friends_provider.dart';
import '../../providers/friend_search_provider.dart';
import '../../data/user_search_source.dart';
import '../../domain/models/public_profile.dart';

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
  final Map<String, Future<PublicProfile?>> _profileCache = {};

  Future<PublicProfile?> _fetchProfile(String uid) {
    return _profileCache[uid] ??=
        context.read<UserSearchSource>().getProfile(uid).then<PublicProfile?>
            ((value) => value, onError: (_, __) => null);
  }

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
          title: FutureBuilder<PublicProfile?>(
            future: _fetchProfile(f.friendUid),
            builder: (context, snapshot) {
              final name = snapshot.data?.username ?? f.friendUid;
              return Text(name);
            },
          ),
          onTap: () => _showFriendActions(f.friendUid),
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
                      title: FutureBuilder<PublicProfile?>(
                        future: _fetchProfile(r.fromUserId),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.username ?? r.fromUserId;
                          return Text(name);
                        },
                      ),
                      subtitle: Text(r.message ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              await prov.accept(r.fromUserId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_accepted)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () async {
                              await prov.decline(r.fromUserId);
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
                      title: FutureBuilder<PublicProfile?>(
                        future: _fetchProfile(r.toUserId),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.username ?? r.toUserId;
                          return Text(name);
                        },
                      ),
                      subtitle: Text(r.message ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () async {
                          await prov.cancel(r.toUserId);
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

  Future<void> _showFriendActions(String uid) async {
    final profile = await _fetchProfile(uid);
    if (!mounted) return;
    final name = profile?.username ?? uid;
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.friends_action_training_days),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRouter.friendTrainingCalendar,
                  arguments: {'uid': uid, 'name': name},
                );
              },
            ),
            ListTile(
              title: Text(loc.friends_action_open_profile),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.friendDetail, arguments: uid);
              },
            ),
            ListTile(
              title: Text(
                loc.friends_action_remove,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _confirmRemove(uid, name);
              },
            ),
            ListTile(
              title: Text(loc.cancelButton),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(String uid, String name) async {
    final loc = AppLocalizations.of(context)!;
    final prov = context.read<FriendsProvider>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Consumer<FriendsProvider>(
        builder: (context, p, _) => AlertDialog(
          title: Text(loc.friends_remove_title),
          content: Text(loc.friends_remove_message(name)),
          actions: [
            TextButton(
              onPressed: p.isBusy ? null : () => Navigator.pop(ctx, false),
              child: Text(loc.friends_remove_no),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: p.isBusy
                  ? null
                  : () async {
                      try {
                        await prov.remove(uid);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (_) {
                        if (ctx.mounted) Navigator.pop(ctx, false);
                      }
                    },
              child: p.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.friends_remove_yes),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.friends_removed_snackbar)),
      );
    } else if (prov.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error!)),
      );
    }
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
                  final cta = searchProv.ctaFor(p.uid, prov);
                  Widget trailing;
                  switch (cta) {
                    case FriendSearchCta.self:
                      trailing = Text(loc.friends_cta_self);
                      break;
                    case FriendSearchCta.friend:
                      trailing = Text(loc.friends_cta_friend);
                      break;
                    case FriendSearchCta.outgoingPending:
                      trailing = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(loc.friends_cta_pending),
                          TextButton(
                            onPressed: () async {
                              await prov.cancel(p.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_canceled)),
                              );
                            },
                            child: Text(loc.friends_action_cancel),
                          ),
                        ],
                      );
                      break;
                    case FriendSearchCta.incomingPending:
                      trailing = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await prov.accept(p.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_accepted)),
                              );
                            },
                            child: Text(loc.friends_action_accept),
                          ),
                          TextButton(
                            onPressed: () async {
                              await prov.decline(p.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_declined)),
                              );
                            },
                            child: Text(loc.friends_action_decline),
                          ),
                        ],
                      );
                      break;
                    case FriendSearchCta.none:
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
                      break;
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
