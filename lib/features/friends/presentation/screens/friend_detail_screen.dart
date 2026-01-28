import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/public_profile.dart';
import '../../providers/friends_riverpod.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

class FriendDetailScreen extends ConsumerStatefulWidget {
  const FriendDetailScreen({required this.uid, Key? key}) : super(key: key);
  final String uid;
  static Route<void> route(String uid) =>
      MaterialPageRoute(builder: (_) => FriendDetailScreen(uid: uid));
  @override
  ConsumerState<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen> {
  PublicProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final src = ref.read(userSearchSourceProvider);
    try {
      final p = await src.getProfile(widget.uid);
      if (mounted) {
        setState(() => _profile = p);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _profile = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.username ?? 'Profil';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator())
          : _ProfileCard(profile: _profile!),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final PublicProfile profile;
  const _ProfileCard({required this.profile});

  Future<String?> _resolveGymName(String gymCode) async {
    try {
      final catalog = AvatarCatalog.instance; // reuse singleton access
      return catalog.gymNameForCode(gymCode);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gym = profile.primaryGymCode ?? '';
    final avatarPath = AvatarCatalog.instance
        .resolvePathOrFallback(profile.avatarKey ?? 'default', gymId: gym);
    final avatar = CircleAvatar(
      radius: 48,
      backgroundImage: AssetImage(avatarPath),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(height: 12),
          Text(
            profile.username,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (gym.isNotEmpty)
            FutureBuilder<String?>(
              future: _resolveGymName(gym),
              builder: (ctx, snapshot) {
                final gymName = snapshot.data ?? gym;
                return Text(
                  'Gym: $gymName',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                );
              },
            ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profil von ${profile.username}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
