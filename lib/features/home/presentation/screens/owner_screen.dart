import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/home/presentation/widgets/owner/owner_hub_sections.dart';

class OwnerScreen extends ConsumerStatefulWidget {
  const OwnerScreen({super.key, this.onOpenReport, this.onOpenAdmin});

  final VoidCallback? onOpenReport;
  final VoidCallback? onOpenAdmin;

  @override
  ConsumerState<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends ConsumerState<OwnerScreen> {
  bool _hasTappedPrimaryAction = false;

  String get _variant {
    if (!FF.runtimeOwnerHubV1) {
      return 'legacy';
    }
    return FF.runtimeOwnerHubV2 ? 'v2' : 'v1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logOwnerHubViewed();
    });
  }

  @override
  void dispose() {
    if (!_hasTappedPrimaryAction) {
      final auth = ref.read(authControllerProvider);
      unawaited(
        AnalyticsService.logOwnerHubAbort(
          gymId: auth.gymCode ?? 'unknown',
          userId: auth.userId ?? 'unknown',
          reason: 'left_without_primary_action',
        ),
      );
    }
    super.dispose();
  }

  Future<void> _logOwnerHubViewed() async {
    final auth = ref.read(authControllerProvider);
    await AnalyticsService.logOwnerHubViewed(
      gymId: auth.gymCode ?? 'unknown',
      userId: auth.userId ?? 'unknown',
      variant: _variant,
    );
  }

  Future<void> _openOwnerTarget({
    required VoidCallback openTarget,
    required String targetPage,
  }) async {
    final auth = ref.read(authControllerProvider);
    _hasTappedPrimaryAction = true;
    unawaited(
      AnalyticsService.logOwnerHubActionClick(
        gymId: auth.gymCode ?? 'unknown',
        userId: auth.userId ?? 'unknown',
        targetPage: targetPage,
      ),
    );
    openTarget();
  }

  Future<void> _confirmAndReloadClaims(BuildContext context) async {
    final auth = ref.read(authControllerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Berechtigungen neu laden?'),
        content: const Text(
          'Diese Aktion aktualisiert Rollen-Claims vom Server. '
          'Nutze sie nur bei Rollen-Aenderungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Neu laden'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      unawaited(
        AnalyticsService.logOwnerHubAbort(
          gymId: auth.gymCode ?? 'unknown',
          userId: auth.userId ?? 'unknown',
          reason: 'reload_claims_dialog_cancelled',
        ),
      );
      return;
    }

    await auth.refreshClaims();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berechtigungen aktualisiert.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final useHubV1 = FF.runtimeOwnerHubV1;
    final useHubV2 = FF.runtimeOwnerHubV2;
    final quickActions = [
      OwnerQuickAction(
        icon: Icons.insert_chart_outlined,
        title: 'Report',
        subtitle: 'Nutzung, Mitglieder und Trends pro Studio auswerten.',
        onTap: () => _openOwnerTarget(
          openTarget:
              widget.onOpenReport ??
              () => Navigator.of(context).pushNamed(AppRouter.report),
          targetPage: 'report',
        ),
        uiLogEvent: 'OWNER_HUB_NAV_REPORT',
      ),
      OwnerQuickAction(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin',
        subtitle: 'Konfiguration, Geraete und Studio-Verwaltung steuern.',
        onTap: () => _openOwnerTarget(
          openTarget:
              widget.onOpenAdmin ??
              () => Navigator.of(context).pushNamed(AppRouter.admin),
          targetPage: 'admin',
        ),
        uiLogEvent: 'OWNER_HUB_NAV_ADMIN',
      ),
    ];
    final insights = [
      OwnerInsight(
        icon: Icons.fitness_center_rounded,
        label: 'Gym',
        value: (auth.gymCode?.isNotEmpty ?? false)
            ? auth.gymCode!
            : 'Unbekannt',
        helper: 'Aktiver Kontext fuer Owner-Operationen.',
      ),
      const OwnerInsight(
        icon: Icons.layers_rounded,
        label: 'Bottom Bar',
        value: 'Kompakt',
        helper: 'Member-Tabs plus Owner-Hub.',
      ),
      OwnerInsight(
        icon: Icons.verified_user_outlined,
        label: 'Rolle',
        value: auth.isGymOwner ? 'gymowner' : (auth.role ?? 'unknown'),
        helper: 'Access wird zentral ueber AccessTier gesteuert.',
      ),
    ];

    if (!useHubV1) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Owner',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final action in quickActions) ...[
                    ElevatedButton(
                      onPressed: action.onTap,
                      child: Text(action.title),
                    ),
                    if (action != quickActions.last)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Owner',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OwnerQuickActionsSection(actions: quickActions),
                const SizedBox(height: AppSpacing.md),
                OwnerInsightsSection(
                  insights: insights,
                  showBetaHint: useHubV2,
                ),
                if (useHubV2) ...[
                  const SizedBox(height: AppSpacing.md),
                  OwnerDangerZoneSection(
                    onReloadClaimsTap: () => _confirmAndReloadClaims(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
