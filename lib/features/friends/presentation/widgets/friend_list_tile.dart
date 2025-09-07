import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/public_profile.dart';
import '../../providers/friend_presence_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({
    super.key,
    required this.profile,
    required this.presence,
    required this.onTap,
    this.gymId,
  });

  final PublicProfile profile;
  final PresenceState presence;
  final VoidCallback onTap;
  final String? gymId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarKey = profile.avatarKey ?? 'default';
    AuthProvider? auth;
    try {
      auth = Provider.of<AuthProvider>(context, listen: false);
    } catch (_) {
      auth = null;
    }
    final currentGym = gymId ?? auth?.gymCode;
    final path = AvatarCatalog.instance
        .resolvePath(avatarKey, currentGymId: currentGym);
    final image = Image.asset(path, errorBuilder: (_, __, ___) {
      if (kDebugMode) {
        debugPrint('[Avatar] failed to load $path');
      }
      return const Icon(Icons.person);
    });
    final avatar = CircleAvatar(
      radius: 20,
      backgroundImage: image.image,
      child: const Icon(Icons.person),
    );
    final statusColor = presence == PresenceState.workedOutToday
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurfaceVariant;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              key: const ValueKey('status-dot'),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        profile.username,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      minVerticalPadding: 8,
    );
  }
}
