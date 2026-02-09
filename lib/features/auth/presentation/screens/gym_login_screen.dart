import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/network_circle_avatar.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_keyboard_scroll_view.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/login_form.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymLoginScreen extends ConsumerStatefulWidget {
  const GymLoginScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymLoginScreen> createState() => _GymLoginScreenState();
}

class _GymLoginScreenState extends ConsumerState<GymLoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(StorageKeys.preAuthGymId, widget.gymId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymAsync = ref.watch(gymByIdProvider(widget.gymId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: AuthKeyboardScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AuthTheme.spacingM),
          child: gymAsync.when(
            data: (gym) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OfflineBanner(),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AuthTheme.textMuted,
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed(
                            AppRouter.gymAccess,
                            arguments: widget.gymId,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Hero(
                      tag: 'gym-logo-${gym.id}',
                      child: NetworkCircleAvatar(url: gym.logoUrl, radius: 34),
                    ),
                  ),
                  const SizedBox(height: AuthTheme.spacingM),
                  Text(
                    loc.gymLoginTitle(gym.name),
                    textAlign: TextAlign.center,
                    style: AuthTheme.headingStyle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AuthTheme.spacingS),
                  Text(
                    loc.gymAccessSubtitle,
                    textAlign: TextAlign.center,
                    style: AuthTheme.bodyStyle,
                  ),
                  const SizedBox(height: AuthTheme.spacingL),
                  GlassCard(child: const LoginForm()),
                  const SizedBox(height: 18),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  loc.authErrorGeneric(error),
                  textAlign: TextAlign.center,
                  style: AuthTheme.bodyStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
