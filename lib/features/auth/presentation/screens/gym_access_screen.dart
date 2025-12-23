import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymAccessScreen extends ConsumerStatefulWidget {
  const GymAccessScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymAccessScreen> createState() => _GymAccessScreenState();
}

class _GymAccessScreenState extends ConsumerState<GymAccessScreen> {
  bool _isStartingDemo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(StorageKeys.preAuthGymId, widget.gymId);
      await prefs.setString('selectedGymCode', widget.gymId);
      await prefs.setString(StorageKeys.lastUsedGymId, widget.gymId);
    });
  }

  Future<void> _startDemo() async {
    if (_isStartingDemo) return;
    setState(() => _isStartingDemo = true);
    final auth = ref.read(authControllerProvider);
    final result = await auth.enterDemoMode(widget.gymId);
    if (!mounted) return;
    setState(() => _isStartingDemo = false);
    if (result.success) {
      Navigator.of(context).pushReplacementNamed(
        AppRouter.home,
        arguments: 0,
      );
      return;
    }
    final loc = AppLocalizations.of(context)!;
    final message = result.error ?? loc.authErrorGeneric('demo_failed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _changeGym() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(StorageKeys.preAuthGymId);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.gymEntry);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymAsync = ref.watch(gymByIdProvider(widget.gymId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: gymAsync.when(
          data: (gym) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                const SizedBox(height: 16),
                Center(
                  child: Hero(
                    tag: 'gym-logo-${gym.id}',
                    child: gym.logoUrl != null
                        ? CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(gym.logoUrl!),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          )
                        : const CircleAvatar(
                            radius: 36,
                            child: Icon(Icons.fitness_center_outlined),
                          ),
                  ),
                ),
                const SizedBox(height: AuthTheme.spacingS),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: _changeGym,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.gymAccessTitle(gym.name),
                  textAlign: TextAlign.center,
                  style: AuthTheme.headingStyle,
                ),
                const SizedBox(height: AuthTheme.spacingS),
                Text(
                  loc.gymAccessSubtitle,
                  textAlign: TextAlign.center,
                  style: AuthTheme.bodyStyle.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AuthTheme.spacingL),
                GlassCard(
                  child: Column(
                    children: [
                      PremiumButton(
                        text: loc.loginButton,
                        onPressed: () {
                          AnalyticsService.logGymAuthChoice(
                            gymId: widget.gymId,
                            action: 'login',
                          );
                          Navigator.of(context).pushNamed(
                            AppRouter.gymLogin,
                            arguments: widget.gymId,
                          );
                        },
                      ),
                      const SizedBox(height: AuthTheme.spacingM),
                      PremiumButton(
                        text: loc.registerButton,
                        onPressed: () {
                          AnalyticsService.logGymAuthChoice(
                            gymId: widget.gymId,
                            action: 'register',
                          );
                          Navigator.of(context).pushNamed(
                            AppRouter.gymRegisterMethod,
                            arguments: widget.gymId,
                          );
                        },
                      ),
                      const SizedBox(height: AuthTheme.spacingM),
                      PremiumButton(
                        text: loc.gymDemoCta,
                        isOutlined: true,
                        isLoading: _isStartingDemo,
                        onPressed: _isStartingDemo ? null : _startDemo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AuthTheme.spacingM),
                TextButton(
                  onPressed: _changeGym,
                  child: Text(
                    loc.gymChangeSelection,
                    style: AuthTheme.labelStyle.copyWith(
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                loc.authErrorGeneric(error),
                textAlign: TextAlign.center,
                style: AuthTheme.bodyStyle.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
