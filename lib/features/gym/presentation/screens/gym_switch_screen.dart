import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/network_circle_avatar.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymSwitchScreen extends ConsumerStatefulWidget {
  const GymSwitchScreen({super.key});

  @override
  ConsumerState<GymSwitchScreen> createState() => _GymSwitchScreenState();
}

class _GymSwitchScreenState extends ConsumerState<GymSwitchScreen> {
  String? _switchingGymId;
  String? _errorMessage;

  Future<void> _switchGym(String gymId) async {
    if (_switchingGymId != null) return;
    setState(() {
      _switchingGymId = gymId;
      _errorMessage = null;
    });
    final auth = ref.read(authControllerProvider);
    final result = await auth.switchGym(gymId);
    if (!mounted) return;
    if (result.success) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(StorageKeys.lastUsedGymId, gymId);
      Navigator.of(context).pop();
      return;
    }
    final loc = AppLocalizations.of(context)!;
    final message = result.errorCode ?? loc.membershipSyncError;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() => _switchingGymId = null);
  }

  Future<void> _confirmRemoveGym(GymConfig gym, bool isActive) async {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.read(authControllerProvider);
    final gyms = auth.gymCodes ?? [];
    if (gyms.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.gymRemoveLastBlocked)),
      );
      return;
    }
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.gymRemoveTitle(gym.name)),
        content: Text(
          isActive ? loc.gymRemoveActiveMessage : loc.gymRemoveMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.gymRemoveCta),
          ),
        ],
      ),
    );
    if (shouldRemove != true || !mounted) return;
    final result = await auth.removeGymMembership(gym.id);
    if (!mounted) return;
    if (!result.success) {
      final message = result.errorCode ?? loc.membershipSyncError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final gyms = auth.gymCodes ?? [];
    final activeGymId = auth.gymCode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.gymSwitchTitle,
              textAlign: TextAlign.center,
              style: AuthTheme.headingStyle,
            ),
            const SizedBox(height: AuthTheme.spacingS),
            Text(
              loc.gymSwitchSubtitle,
              textAlign: TextAlign.center,
              style: AuthTheme.bodyStyle.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AuthTheme.spacingL),
            Expanded(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: gyms.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            loc.missingMembershipError,
                            textAlign: TextAlign.center,
                            style: AuthTheme.bodyStyle.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: gyms.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        itemBuilder: (context, index) {
                          final gymId = gyms[index];
                          final isActive = gymId == activeGymId;
                          final isProcessing = _switchingGymId == gymId;
                          return Consumer(
                            builder: (context, ref, _) {
                              final gymAsync = ref.watch(gymByIdProvider(gymId));
                              return gymAsync.when(
                                data: (gym) {
                                  final canRemove = gyms.length > 1;
                                  return AnimatedContainer(
                                    duration: AuthTheme.animationDurationMedium,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isActive ? 12 : 0,
                                      vertical: isActive ? 4 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: isActive
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.transparent,
                                    ),
                                    child: ListTile(
                                      leading: NetworkCircleAvatar(
                                        url: gym.logoUrl,
                                      ),
                                      title: Text(
                                        gym.name,
                                        style: AuthTheme.bodyStyle,
                                      ),
                                      subtitle: Text(
                                        isActive
                                            ? loc.gymSwitchActiveLabel
                                            : gym.code,
                                        style: AuthTheme.labelStyle,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isProcessing)
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white70,
                                              ),
                                            )
                                          else if (isActive)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white70,
                                            ),
                                          IconButton(
                                            tooltip: loc.gymRemoveCta,
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: canRemove
                                                  ? Colors.white70
                                                  : Colors.white24,
                                            ),
                                            onPressed: canRemove
                                                ? () => _confirmRemoveGym(
                                                      gym,
                                                      isActive,
                                                    )
                                                : null,
                                          ),
                                        ],
                                      ),
                                      onTap: isActive || isProcessing
                                          ? null
                                          : () => _switchGym(gymId),
                                    ),
                                  );
                                },
                                loading: () => ListTile(
                                  title: Text(
                                    gymId,
                                    style: AuthTheme.bodyStyle,
                                  ),
                                  subtitle: Text(
                                    loc.loadingLabel,
                                    style: AuthTheme.labelStyle,
                                  ),
                                  trailing: IconButton(
                                    tooltip: loc.gymRemoveCta,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white24,
                                    ),
                                    onPressed: null,
                                  ),
                                ),
                                error: (_, __) => ListTile(
                                  title: Text(
                                    gymId,
                                    style: AuthTheme.bodyStyle,
                                  ),
                                  subtitle: Text(
                                    loc.loadingErrorLabel,
                                    style: AuthTheme.labelStyle,
                                  ),
                                  trailing: IconButton(
                                    tooltip: loc.gymRemoveCta,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white24,
                                    ),
                                    onPressed: null,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AuthTheme.spacingS),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFF8A80),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: AuthTheme.spacingS),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.gymAddMembership);
              },
              child: Text(
                loc.gymAddMembershipCta,
                style: AuthTheme.labelStyle.copyWith(
                  color: Colors.white70,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
