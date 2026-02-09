import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_keyboard_scroll_view.dart';
import 'package:tapem/features/auth/presentation/widgets/animated_tab_indicator.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/login_form.dart';
import 'package:tapem/features/auth/presentation/widgets/registration_form.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = ref.watch(authControllerProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: Stack(
          children: [
            AuthKeyboardScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AuthTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Text(
                    loc.authTitle,
                    textAlign: TextAlign.center,
                    style: AuthTheme.headingStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.gymEntrySubtitle,
                    textAlign: TextAlign.center,
                    style: AuthTheme.bodyStyle,
                  ),
                  const SizedBox(height: AuthTheme.spacingL),
                  AnimatedTabIndicator(
                    controller: _tabController,
                    tabs: [loc.loginButton, loc.registerButton],
                  ),
                  const SizedBox(height: AuthTheme.spacingL),
                  GlassCard(
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return AnimatedSwitcher(
                          duration: AuthTheme.animationDurationMedium,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1,
                                child: child,
                              ),
                            );
                          },
                          child: _tabController.index == 0
                              ? const LoginForm(key: ValueKey('login'))
                              : const RegistrationForm(
                                  key: ValueKey('register'),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
            if (authProv.isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withOpacity(0.48),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
