import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymRegisterMethodScreen extends ConsumerStatefulWidget {
  const GymRegisterMethodScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymRegisterMethodScreen> createState() =>
      _GymRegisterMethodScreenState();
}

class _GymRegisterMethodScreenState
    extends ConsumerState<GymRegisterMethodScreen> {
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
                            radius: 34,
                            backgroundImage: NetworkImage(gym.logoUrl!),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          )
                        : const CircleAvatar(
                            radius: 34,
                            child: Icon(Icons.fitness_center_outlined),
                          ),
                  ),
                ),
                const SizedBox(height: AuthTheme.spacingS),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                      AppRouter.gymAccess,
                      arguments: widget.gymId,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.gymRegisterMethodTitle,
                  textAlign: TextAlign.center,
                  style: AuthTheme.headingStyle,
                ),
                const SizedBox(height: AuthTheme.spacingS),
                Text(
                  loc.gymRegisterMethodSubtitle(gym.name),
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
                        text: loc.gymRegisterWithNfc,
                        onPressed: () {
                          AnalyticsService.logGymRegisterMethod(
                            gymId: widget.gymId,
                            method: 'nfc',
                          );
                          Navigator.of(context).pushNamed(
                            AppRouter.gymRegister,
                            arguments: GymRegisterArgs(
                              gymId: widget.gymId,
                              method: GymRegisterMethod.nfc,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AuthTheme.spacingM),
                      PremiumButton(
                        text: loc.gymRegisterWithCode,
                        onPressed: () {
                          AnalyticsService.logGymRegisterMethod(
                            gymId: widget.gymId,
                            method: 'code',
                          );
                          Navigator.of(context).pushNamed(
                            AppRouter.gymRegister,
                            arguments: GymRegisterArgs(
                              gymId: widget.gymId,
                              method: GymRegisterMethod.gymCode,
                            ),
                          );
                        },
                      ),
                    ],
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

enum GymRegisterMethod { gymCode, nfc }

class GymRegisterArgs {
  const GymRegisterArgs({
    required this.gymId,
    required this.method,
    this.prefilledGymCode,
    this.gymValidator,
  });

  final String gymId;
  final GymRegisterMethod method;
  final String? prefilledGymCode;
  final ValidateGymCode? gymValidator;
}
