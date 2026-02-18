import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/home/application/owner_workspace_provider.dart';
import 'package:tapem/features/home/presentation/widgets/owner/owner_hub_sections.dart';
import 'package:tapem/l10n/app_localizations.dart';

class OwnerScreen extends ConsumerStatefulWidget {
  const OwnerScreen({super.key, this.onOpenReport, this.onOpenAdmin});

  final VoidCallback? onOpenReport;
  final VoidCallback? onOpenAdmin;

  @override
  ConsumerState<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends ConsumerState<OwnerScreen> {
  bool _hasTappedPrimaryAction = false;
  String _analyticsGymId = 'unknown';
  String _analyticsUserId = 'unknown';

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
      unawaited(
        AnalyticsService.logOwnerHubAbort(
          gymId: _analyticsGymId,
          userId: _analyticsUserId,
          reason: 'left_without_owner_action',
        ),
      );
    }
    super.dispose();
  }

  void _cacheAnalyticsIdentity({
    required String? gymId,
    required String? userId,
  }) {
    final resolvedGymId = gymId?.trim();
    final resolvedUserId = userId?.trim();
    _analyticsGymId = (resolvedGymId != null && resolvedGymId.isNotEmpty)
        ? resolvedGymId
        : 'unknown';
    _analyticsUserId = (resolvedUserId != null && resolvedUserId.isNotEmpty)
        ? resolvedUserId
        : 'unknown';
  }

  Future<void> _logOwnerHubViewed() async {
    await AnalyticsService.logOwnerHubViewed(
      gymId: _analyticsGymId,
      userId: _analyticsUserId,
      variant: 'phase1',
    );
  }

  Future<void> _openOwnerTarget({
    required VoidCallback openTarget,
    required String targetPage,
  }) async {
    _hasTappedPrimaryAction = true;
    unawaited(
      AnalyticsService.logOwnerHubActionClick(
        gymId: _analyticsGymId,
        userId: _analyticsUserId,
        targetPage: targetPage,
      ),
    );
    openTarget();
  }

  Future<void> _refreshDashboard(String gymId) async {
    ref.invalidate(ownerWorkspaceSnapshotProvider(gymId));
    await ref.read(ownerWorkspaceSnapshotProvider(gymId).future);
  }

  Future<void> _openNamedRoute(
    String routeName, {
    Object? arguments,
    String? analyticsTarget,
  }) {
    return _openOwnerTarget(
      openTarget: () => Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(routeName, arguments: arguments),
      targetPage: analyticsTarget ?? routeName,
    );
  }

  List<OwnerTask> _buildTodayTasks(String gymId, OwnerWorkspaceSnapshot data) {
    final loc = AppLocalizations.of(context)!;
    final tasks = <OwnerTask>[];

    if (data.openFeedbackCount > 0) {
      tasks.add(
        OwnerTask(
          icon: Icons.feedback_outlined,
          title: loc.ownerTaskOpenFeedbackTitle(data.openFeedbackCount),
          subtitle: loc.ownerTaskOpenFeedbackSubtitle,
          priority: OwnerTaskPriority.high,
          onTap: () => _openNamedRoute(
            AppRouter.feedbackOverview,
            arguments: gymId,
            analyticsTarget: 'feedback_overview',
          ),
        ),
      );
    }

    if (data.activeChallengeCount == 0) {
      tasks.add(
        OwnerTask(
          icon: Icons.emoji_events_outlined,
          title: loc.ownerTaskPlanChallengeTitle,
          subtitle: loc.ownerTaskPlanChallengeSubtitle,
          priority: OwnerTaskPriority.high,
          onTap: () => _openNamedRoute(
            AppRouter.manageChallenges,
            analyticsTarget: 'manage_challenges',
          ),
        ),
      );
    }

    if (data.openSurveyCount == 0) {
      tasks.add(
        OwnerTask(
          icon: Icons.poll_outlined,
          title: loc.ownerTaskStartSurveyTitle,
          subtitle: loc.ownerTaskStartSurveySubtitle,
          priority: OwnerTaskPriority.medium,
          onTap: () => _openNamedRoute(
            AppRouter.surveyOverview,
            arguments: gymId,
            analyticsTarget: 'survey_overview',
          ),
        ),
      );
    }

    if (data.deviceCount == 0) {
      tasks.add(
        OwnerTask(
          icon: Icons.fitness_center_outlined,
          title: loc.ownerTaskCreateFirstDeviceTitle,
          subtitle: loc.ownerTaskCreateFirstDeviceSubtitle,
          priority: OwnerTaskPriority.high,
          onTap: () => _openNamedRoute(
            AppRouter.adminDevices,
            analyticsTarget: 'admin_devices',
          ),
        ),
      );
    }

    if (data.memberCount < 5) {
      tasks.add(
        OwnerTask(
          icon: Icons.groups_outlined,
          title: loc.ownerTaskCheckMembersTitle,
          subtitle: loc.ownerTaskCheckMembersSubtitle,
          priority: OwnerTaskPriority.low,
          onTap: () => _openOwnerTarget(
            openTarget:
                widget.onOpenReport ??
                () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRouter.report),
            targetPage: 'report',
          ),
        ),
      );
    }

    return tasks;
  }

  List<OwnerQuickAction> _buildQuickActions(
    String gymId,
    AppLocalizations loc,
  ) {
    return [
      OwnerQuickAction(
        icon: Icons.insert_chart_outlined,
        title: loc.reportTitle,
        subtitle: loc.ownerQuickActionReportSubtitle,
        onTap: () => _openOwnerTarget(
          openTarget:
              widget.onOpenReport ??
              () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRouter.report),
          targetPage: 'report',
        ),
        uiLogEvent: 'OWNER_NAV_REPORT',
      ),
      OwnerQuickAction(
        icon: Icons.groups_rounded,
        title: loc.reportMembersButtonTitle,
        subtitle: loc.ownerQuickActionMembersSubtitle,
        onTap: () => _openNamedRoute(
          AppRouter.adminRemoveUsers,
          analyticsTarget: 'admin_remove_users',
        ),
        uiLogEvent: 'OWNER_NAV_MEMBERS',
      ),
      OwnerQuickAction(
        icon: Icons.fitness_center_outlined,
        title: loc.challengeAdminFieldDevices,
        subtitle: loc.ownerQuickActionDevicesSubtitle,
        onTap: () => _openNamedRoute(
          AppRouter.adminDevices,
          analyticsTarget: 'admin_devices',
        ),
        uiLogEvent: 'OWNER_NAV_DEVICES',
      ),
      OwnerQuickAction(
        icon: Icons.feedback_outlined,
        title: loc.reportFeedbackButtonTitle,
        subtitle: loc.ownerQuickActionFeedbackSubtitle,
        onTap: () => _openNamedRoute(
          AppRouter.feedbackOverview,
          arguments: gymId,
          analyticsTarget: 'feedback_overview',
        ),
        uiLogEvent: 'OWNER_NAV_FEEDBACK',
      ),
      OwnerQuickAction(
        icon: Icons.poll_outlined,
        title: loc.reportSurveysButtonTitle,
        subtitle: loc.ownerQuickActionSurveysSubtitle,
        onTap: () => _openNamedRoute(
          AppRouter.surveyOverview,
          arguments: gymId,
          analyticsTarget: 'survey_overview',
        ),
        uiLogEvent: 'OWNER_NAV_SURVEYS',
      ),
      OwnerQuickAction(
        icon: Icons.emoji_events_outlined,
        title: loc.challengeAdminTitle,
        subtitle: loc.ownerQuickActionChallengesSubtitle,
        onTap: () => _openNamedRoute(
          AppRouter.manageChallenges,
          analyticsTarget: 'manage_challenges',
        ),
        uiLogEvent: 'OWNER_NAV_CHALLENGES',
      ),
      OwnerQuickAction(
        icon: Icons.local_offer_outlined,
        title: loc.ownerQuickActionDealsTitle,
        subtitle: loc.ownerQuickActionDealsSubtitle,
        onTap: () => _openNamedRoute(
          AppRouter.adminDeals,
          analyticsTarget: 'admin_deals',
        ),
        uiLogEvent: 'OWNER_NAV_DEALS',
      ),
      OwnerQuickAction(
        icon: Icons.admin_panel_settings_outlined,
        title: loc.adminDashboardTitle,
        subtitle: loc.ownerQuickActionAdminSubtitle,
        onTap: () => _openOwnerTarget(
          openTarget:
              widget.onOpenAdmin ??
              () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRouter.admin),
          targetPage: 'admin_dashboard',
        ),
        uiLogEvent: 'OWNER_NAV_ADMIN',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loc = AppLocalizations.of(context)!;
    _cacheAnalyticsIdentity(gymId: auth.gymCode, userId: auth.userId);

    if (!auth.canManageGym) {
      return SafeArea(
        child: OwnerStateSection(
          icon: Icons.lock_outline,
          title: loc.commonNoAccess,
          subtitle: loc.ownerNoAccessSubtitle,
        ),
      );
    }

    final gymId = auth.gymCode?.trim() ?? '';
    if (gymId.isEmpty) {
      return SafeArea(
        child: OwnerStateSection(
          icon: Icons.location_searching_outlined,
          title: loc.ownerGymContextMissingTitle,
          subtitle: loc.ownerGymContextMissingSubtitle,
          ctaLabel: loc.selectGymTitle,
          onTap: () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRouter.selectGym),
        ),
      );
    }

    final dashboardAsync = ref.watch(ownerWorkspaceSnapshotProvider(gymId));
    final quickActions = _buildQuickActions(gymId, loc);

    return dashboardAsync.when(
      loading: () =>
          const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (error, stack) => SafeArea(
        child: OwnerStateSection(
          icon: Icons.error_outline,
          title: loc.ownerDashboardLoadErrorTitle,
          subtitle: loc.ownerDashboardLoadErrorSubtitle(error.toString()),
          ctaLabel: loc.communityRetryButton,
          onTap: () => _refreshDashboard(gymId),
        ),
      ),
      data: (data) {
        final metrics = [
          OwnerMetric(
            icon: Icons.groups_outlined,
            label: loc.ownerMetricMembersLabel,
            value: '${data.memberCount}',
            helper: loc.ownerMetricMembersHelper,
          ),
          OwnerMetric(
            icon: Icons.fitness_center_outlined,
            label: loc.ownerMetricDevicesLabel,
            value: '${data.deviceCount}',
            helper: loc.ownerMetricDevicesHelper,
          ),
          OwnerMetric(
            icon: Icons.feedback_outlined,
            label: loc.ownerMetricOpenFeedbackLabel,
            value: '${data.openFeedbackCount}',
            helper: loc.ownerMetricOpenFeedbackHelper,
          ),
          OwnerMetric(
            icon: Icons.poll_outlined,
            label: loc.ownerMetricOpenSurveysLabel,
            value: '${data.openSurveyCount}',
            helper: loc.ownerMetricOpenSurveysHelper,
          ),
          OwnerMetric(
            icon: Icons.emoji_events_outlined,
            label: loc.ownerMetricActiveChallengesLabel,
            value: '${data.activeChallengeCount}',
            helper: loc.ownerMetricActiveChallengesHelper,
          ),
        ];

        final todayTasks = _buildTodayTasks(gymId, data);

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _refreshDashboard(gymId),
            child: FocusTraversalGroup(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  OwnerWorkspaceHeaderSection(
                    gymId: gymId,
                    generatedAt: data.generatedAt,
                  ),
                  if (data.isEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    OwnerStateSection(
                      icon: Icons.insights_outlined,
                      title: loc.ownerNoDataTitle,
                      subtitle: loc.ownerNoDataSubtitle,
                      ctaLabel: loc.adminDashboardCreateDevice,
                      onTap: () => _openNamedRoute(
                        AppRouter.adminDevices,
                        analyticsTarget: 'admin_devices',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  OwnerMetricsSection(metrics: metrics),
                  const SizedBox(height: AppSpacing.md),
                  OwnerTaskSection(tasks: todayTasks),
                  const SizedBox(height: AppSpacing.md),
                  OwnerQuickActionsSection(actions: quickActions),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
