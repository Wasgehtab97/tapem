import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../providers/friends_riverpod.dart';
import '../../domain/models/public_profile.dart';
import '../widgets/friend_list_tile.dart';

class FriendsHomeScreen extends ConsumerStatefulWidget {
  const FriendsHomeScreen({Key? key}) : super(key: key);
  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const FriendsHomeScreen());
  @override
  ConsumerState<FriendsHomeScreen> createState() => _FriendsHomeScreenState();
}

class _FriendsHomeScreenState extends ConsumerState<FriendsHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final Map<String, Future<PublicProfile?>> _profileCache = {};

  Future<PublicProfile?> _fetchProfile(String uid) {
    return _profileCache[uid] ??=
        ref.read(userSearchSourceProvider).getProfile(uid).then<PublicProfile?>
            ((value) => value, onError: (_, __) => null);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        ref.read(friendsProvider.notifier).markIncomingSeen();
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
    final friendsState = ref.watch(friendsProvider);
    final searchState = ref.watch(friendSearchProvider);
    final chatSummaries = ref.watch(friendChatSummaryProvider);
    final presenceState = ref.watch(friendPresenceProvider);
    final authState = ref.watch(authViewStateProvider);
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
          _friendsTab(friendsState, chatSummaries, presenceState, loc),
          _requestsTab(friendsState, loc),
          _searchTab(friendsState, searchState, loc, authState),
        ],
      ),
    );
  }

  Widget _friendsTab(
    FriendsState friends,
    FriendChatSummaryState chats,
    FriendPresenceState presence,
    AppLocalizations loc,
  ) {
    final friendsList = friends.friends;
    if (friendsList.isEmpty) {
      return Center(child: Text(loc.friends_empty_friends));
    }
    return ListView.builder(
      itemCount: friendsList.length,
      itemBuilder: (_, i) {
        final f = friendsList[i];
        return FutureBuilder<PublicProfile?>(
          future: _fetchProfile(f.friendUid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            if (profile == null) {
              return const ListTile(title: Text('...'));
            }
            final summary = chats.summaryFor(f.friendUid);
            final hasUnread = summary?.hasUnread ?? false;
            return FriendListTile(
              profile: profile,
              presence: presence.stateFor(f.friendUid),
              onTap: () => _showFriendActions(f.friendUid),
              trailing: hasUnread
                  ? Icon(
                      Icons.mark_unread_chat_alt,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _requestsTab(FriendsState friends, AppLocalizations loc) {
    return Column(
      children: [
        Expanded(
          child: friends.incomingPending.isEmpty
              ? Center(child: Text(loc.friends_empty_incoming))
              : ListView.builder(
                  itemCount: friends.incomingPending.length,
                  itemBuilder: (_, i) {
                    final r = friends.incomingPending[i];
                    return FutureBuilder<PublicProfile?>(
                      future: _fetchProfile(r.fromUserId),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        if (profile == null) {
                          return const ListTile(title: Text('...'));
                        }
                        return FriendListTile(
                          profile: profile,
                          subtitle: r.message,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () async {
                                  await ref
                                      .read(friendsProvider.notifier)
                                      .accept(r.fromUserId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(loc.friends_snackbar_accepted)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  await ref
                                      .read(friendsProvider.notifier)
                                      .decline(r.fromUserId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(loc.friends_snackbar_declined)),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        const Divider(),
        Expanded(
          child: friends.outgoingPending.isEmpty
              ? Center(child: Text(loc.friends_empty_outgoing))
              : ListView.builder(
                  itemCount: friends.outgoingPending.length,
                  itemBuilder: (_, i) {
                    final r = friends.outgoingPending[i];
                    return FutureBuilder<PublicProfile?>(
                      future: _fetchProfile(r.toUserId),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        if (profile == null) {
                          return const ListTile(title: Text('...'));
                        }
                        return FriendListTile(
                          profile: profile,
                          subtitle: r.message,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () async {
                              await ref
                                  .read(friendsProvider.notifier)
                                  .cancel(r.toUserId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_canceled)),
                              );
                            },
                          ),
                        );
                      },
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
              title: Text(loc.friends_action_chat),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRouter.friendChat,
                  arguments: {'uid': uid, 'name': name},
                );
                ref.read(friendChatSummaryProvider.notifier).markRead(uid);
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
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(friendsProvider);
          final notifier = ref.read(friendsProvider.notifier);
          return AlertDialog(
            title: Text(loc.friends_remove_title),
            content: Text(loc.friends_remove_message(name)),
            actions: [
              TextButton(
              onPressed:
                  state.isBusy ? null : () => Navigator.pop(ctx, false),
              child: Text(loc.friends_remove_no),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: state.isBusy
                  ? null
                  : () async {
                      try {
                        await notifier.remove(uid);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (_) {
                        if (ctx.mounted) Navigator.pop(ctx, false);
                      }
                    },
              child: state.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.friends_remove_yes),
            ),
          ],
          );
        },
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.friends_removed_snackbar)),
      );
    } else if (ref.read(friendsProvider).error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(friendsProvider).error!)),
      );
    }
  }

  Widget _searchTab(
    FriendsState friends,
    FriendSearchState searchState,
    AppLocalizations loc,
    AuthViewState authState,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) =>
                ref.read(friendSearchProvider.notifier).updateQuery(v),
            decoration: InputDecoration(labelText: loc.friends_tab_search),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (_) {
              if (searchState.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_searchCtrl.text.trim().length < 2) {
                return Center(child: Text(loc.friends_search_min_chars));
              }
              if (searchState.error != null) {
                return Center(child: Text(searchState.error!));
              }
              if (searchState.results.isEmpty) {
                return Center(child: Text(loc.friends_empty_search));
              }
              return ListView.builder(
                itemCount: searchState.results.length,
                itemBuilder: (_, i) {
                  final p = searchState.results[i];
                  final cta =
                      ref.read(friendSearchProvider.notifier).ctaFor(p.uid, friends);
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
                              await ref
                                  .read(friendsProvider.notifier)
                                  .cancel(p.uid);
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
                              await ref
                                  .read(friendsProvider.notifier)
                                  .accept(p.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.friends_snackbar_accepted)),
                              );
                            },
                            child: Text(loc.friends_action_accept),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref
                                  .read(friendsProvider.notifier)
                                  .decline(p.uid);
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
                            await ref
                                .read(friendsProvider.notifier)
                                .sendRequest(p.uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.friends_snackbar_sent)),
                            );
                          } catch (_) {
                            final msg = ref.read(friendsProvider).error ?? 'Error';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        },
                        child: Text(loc.friends_action_send),
                      );
                      break;
                  }
                  return FriendListTile(
                    profile: p,
                    gymId: p.primaryGymCode ?? authState.gymCode,
                    subtitle: p.primaryGymCode,
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
