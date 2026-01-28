import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
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
          _friendsTab(friendsState, presenceState, loc),
          _requestsTab(friendsState, loc),
          _searchTab(friendsState, searchState, loc, authState),
        ],
      ),
    );
  }

  Widget _friendsTab(
    FriendsState friends,
    FriendPresenceState presence,
    AppLocalizations loc,
  ) {
    final friendsList = friends.friends;
    
    if (friendsList.isEmpty) {
      return _buildPremiumEmptyState(
        icon: Icons.people_outline,
        title: loc.friends_empty_friends,
        subtitle: 'Füge Freunde hinzu, um gemeinsam zu trainieren!',
        gradientColors: [Color(0xFF6B8CFF), Color(0xFF9B6CFF)],
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: friendsList.length,
      itemBuilder: (_, i) {
        final f = friendsList[i];
        return FutureBuilder<PublicProfile?>(
          future: _fetchProfile(f.friendUid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmerCard(),
              );
            }
            if (profile == null) {
              // Profil existiert nicht mehr (z.B. User in Firestore gelöscht).
              // Zeile komplett ausblenden – inklusive Padding.
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFriendCard(
                profile: profile,
                presence: presence.stateFor(f.friendUid),
                onTap: () => _showFriendActions(f.friendUid),
              ),
            );
          },
        );
      },
    );
  }

  Widget _requestsTab(FriendsState friends, AppLocalizations loc) {
    return Column(
      children: [
        // Incoming Requests Section
        Expanded(
          child: friends.incomingPending.isEmpty
              ? _buildPremiumEmptyState(
                  icon: Icons.inbox_outlined,
                  title: loc.friends_empty_incoming,
                  subtitle: 'Neue Anfragen erscheinen hier',
                  gradientColors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inbox, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Eingehende Anfragen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${friends.incomingPending.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: friends.incomingPending.length,
                        itemBuilder: (_, i) {
                          final r = friends.incomingPending[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FutureBuilder<PublicProfile?>(
                              future: _fetchProfile(r.fromUserId),
                              builder: (context, snapshot) {
                                final profile = snapshot.data;
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildShimmerCard();
                                }
                                if (profile == null) {
                                  return const SizedBox.shrink();
                                }
                                return _buildRequestCard(
                                  profile: profile,
                                  message: r.message,
                                  isIncoming: true,
                                  onAccept: () async {
                                    await ref
                                        .read(friendsProvider.notifier)
                                        .accept(r.fromUserId);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(loc.friends_snackbar_accepted)),
                                    );
                                  },
                                  onDecline: () async {
                                    await ref
                                        .read(friendsProvider.notifier)
                                        .decline(r.fromUserId);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(loc.friends_snackbar_declined)),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
            ),
          ),
        ),
        // Outgoing Requests Section
        Expanded(
          child: friends.outgoingPending.isEmpty
              ? _buildPremiumEmptyState(
                  icon: Icons.send_outlined,
                  title: loc.friends_empty_outgoing,
                  subtitle: 'Versendete Anfragen werden hier angezeigt',
                  gradientColors: [Color(0xFF6BCF7F), Color(0xFF4CAF50)],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6BCF7F), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ausgehende Anfragen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ' ${friends.outgoingPending.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: friends.outgoingPending.length,
                        itemBuilder: (_, i) {
                          final r = friends.outgoingPending[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FutureBuilder<PublicProfile?>(
                              future: _fetchProfile(r.toUserId),
                              builder: (context, snapshot) {
                                final profile = snapshot.data;
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildShimmerCard();
                                }
                                if (profile == null) {
                                  return const SizedBox.shrink();
                                }
                                return _buildRequestCard(
                                  profile: profile,
                                  message: r.message,
                                  isIncoming: false,
                                  onCancel: () async {
                                    await ref
                                        .read(friendsProvider.notifier)
                                        .cancel(r.toUserId);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(loc.friends_snackbar_canceled)),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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

  Widget _buildPremiumEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard({
    required PublicProfile profile,
    required PresenceState? presence,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final rawKey = profile.avatarKey ?? 'default';
    final path = AvatarCatalog.instance.resolvePathOrFallback(rawKey);
    
    final statusColor = presence == PresenceState.workedOutToday
        ? const Color(0xFF4CAF50)
        : Colors.grey[400];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor ?? Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (statusColor ?? Colors.transparent).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          presence == PresenceState.workedOutToday
                              ? 'Heute trainiert'
                              : 'Offline',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required PublicProfile profile,
    required String? message,
    required bool isIncoming,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
    VoidCallback? onCancel,
  }) {
    final theme = Theme.of(context);
    final rawKey = profile.avatarKey ?? 'default';
    final path = AvatarCatalog.instance.resolvePathOrFallback(rawKey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncoming 
              ? const Color(0xFFFF6B9D).withOpacity(0.2)
              : const Color(0xFF6BCF7F).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isIncoming ? const Color(0xFFFF6B9D) : const Color(0xFF6BCF7F)).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isIncoming ? const Color(0xFFFF6B9D) : const Color(0xFF6BCF7F),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message != null && message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isIncoming) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Annehmen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Ablehnen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Anfrage zurückziehen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
