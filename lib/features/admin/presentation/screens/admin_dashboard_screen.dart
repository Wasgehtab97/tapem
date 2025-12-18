// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/premium_action_card.dart';
import 'package:tapem/core/widgets/premium_leading_icon.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final loc = AppLocalizations.of(context)!;
    
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.adminAreaTitle)),
        body: Center(child: Text(loc.adminAreaNoPermission)),
      );
    }

    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(loc.adminDashboardTitle),
        foregroundColor: brandColor,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminActionList(
                  actions: [
                    _AdminAction(
                      icon: Icons.fitness_center,
                      title: loc.challengeAdminFieldDevices, // "Geräte"
                      subtitle: loc.adminDashboardCreateDevice, // "Geräte verwalten & erstellen" - using create string as proxy for now or generic
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.adminDevices);
                      },
                    ),
                    _AdminAction(
                      icon: Icons.accessibility_new,
                      title: loc.muscleGroupTitle,
                      subtitle: 'Muskelgruppen & Kategorien bearbeiten', // Hardcoded for now as no specific loc string exists
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.manageMuscleGroups);
                      },
                    ),
                    _AdminAction(
                      icon: Icons.emoji_events,
                      title: loc.challengeAdminTitle,
                      subtitle: 'Challenges erstellen & verwalten',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.manageChallenges);
                      },
                    ),
                    _AdminAction(
                      icon: Icons.person_outline,
                      title: loc.admin_symbols_title,
                      subtitle: 'Benutzer-Symbole & Ränge',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.adminSymbols);
                      },
                    ),
                    _AdminAction(
                      icon: Icons.person_remove_alt_1,
                      title: 'Nutzer entfernen',
                      subtitle: 'Testnutzer & Daten bereinigen',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.adminRemoveUsers);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _AdminActionList extends StatelessWidget {
  final List<_AdminAction> actions;

  const _AdminActionList({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final action in actions) ...[
          SizedBox(
            width: double.infinity,
            child: PremiumActionCard(
              title: action.title,
              subtitle: action.subtitle,
              leading: PremiumLeadingIcon(icon: action.icon),
              onTap: action.onTap,
              uiLogEvent: 'ADMIN_NAV_${action.title.toUpperCase().replaceAll(' ', '_')}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
