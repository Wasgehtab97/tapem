import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/animated_tab_indicator.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/login_form.dart';
import 'package:tapem/features/auth/presentation/widgets/registration_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
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
    final authProv = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Make scaffold transparent so background shows through
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                // Logo / Title Area
                Center(
                  child: Text(
                    loc.authTitle,
                    style: AuthTheme.headingStyle,
                  ),
                ),
                const SizedBox(height: AuthTheme.spacingL),
                
                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AuthTheme.spacingM),
                    child: Column(
                      children: [
                        // Custom Tab Bar
                        AnimatedTabIndicator(
                          controller: _tabController,
                          tabs: [loc.loginButton, loc.registerButton],
                        ),
                        
                        const SizedBox(height: AuthTheme.spacingL),
                        
                        // Forms Container
                        GlassCard(
                          child: AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SizeTransition(
                                      sizeFactor: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _tabController.index == 0
                                    ? const LoginForm(key: ValueKey('login'))
                                    : const RegistrationForm(key: ValueKey('register')),
                              );
                            },
                          ),
                        ),
                        // Bottom spacing
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Loading Overlay
            if (authProv.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
