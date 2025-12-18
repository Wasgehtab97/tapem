import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/public_profile.dart';
import '../../providers/friend_presence_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

class FriendListTile extends ConsumerWidget {
  const FriendListTile({
    super.key,
    required this.profile,
    this.presence,
    this.onTap,
    this.gymId,
    this.subtitle,
    this.trailing,
    this.onAvatarTap,
  });

  final PublicProfile profile;
  final PresenceState? presence;
  final VoidCallback? onTap;
  final String? gymId;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawKey = profile.avatarKey ?? 'default';
    final authView = ref.watch(authViewStateProvider);
    final currentGym = gymId ?? authView.gymCode;
    final path =
        AvatarCatalog.instance.resolvePathOrFallback(rawKey, gymId: currentGym);
    final image = Image.asset(path, errorBuilder: (_, __, ___) {
      if (kDebugMode) {
        debugPrint('[Avatar] failed to load $path');
      }
      return const Icon(Icons.person);
    });
    final avatar = CircleAvatar(
      radius: 20,
      backgroundImage: image.image,
    );
    Widget leading = avatar;
    if (presence != null) {
      final statusColor = presence == PresenceState.workedOutToday
          ? theme.colorScheme.secondary
          : theme.colorScheme.onSurfaceVariant;
      leading = Stack(
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
      );
    }
    if (onAvatarTap != null) {
      leading = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onAvatarTap,
        child: leading,
      );
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: leading,
      title: Text(
        profile.username,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
      minVerticalPadding: 8,
    );
  }
}
