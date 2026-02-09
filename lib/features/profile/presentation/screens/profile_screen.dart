import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/features/friends/providers/friends_riverpod.dart';
import 'package:tapem/features/coaching/application/coaching_providers.dart'
    as coaching;
import 'package:tapem/features/coaching/application/coach_invite_providers.dart'
    as coach_invites;
import 'package:tapem/features/coaching/presentation/screens/select_coach_screen.dart';
import 'package:tapem/features/coaching/presentation/screens/invite_external_coach_screen.dart';
import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/presentation/widgets/daily_xp_card.dart';
import 'package:tapem/features/profile/presentation/widgets/profile_coaching_button.dart';
import 'package:tapem/features/profile/presentation/widgets/profile_hub_button.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/presentation/widgets/plan_selection_sheet.dart';
import 'package:tapem/features/training_plan/presentation/widgets/training_day_action_sheet.dart';
import '../widgets/daily_xp_avatar.dart';
import '../widgets/calendar.dart';
import '../widgets/calendar_popup.dart';
import '../../../survey/presentation/screens/survey_vote_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friends_home_screen.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/training_plan/presentation/widgets/plan_color_palette.dart';
import 'package:tapem/features/profile/presentation/screens/profile_stats_screen.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/presentation/workout_finish_flow.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/bootstrap/navigation.dart';

const bool enableFriends = true;

enum _ActiveTrainingAction { save, discard }

class ProfileScreen extends riverpod.ConsumerStatefulWidget {
  const ProfileScreen({
    Key? key,
    this.onOpenProgress,
    this.onOpenNutrition,
    this.onOpenPlan,
    this.onOpenDiscoverStats,
    this.onOpenDiscoverCommunity,
    this.onOpenDiscoverSurveys,
  }) : super(key: key);

  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenNutrition;
  final VoidCallback? onOpenPlan;
  final VoidCallback? onOpenDiscoverStats;
  final VoidCallback? onOpenDiscoverCommunity;
  final VoidCallback? onOpenDiscoverSurveys;

  @override
  riverpod.ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends riverpod.ConsumerState<ProfileScreen> {
  static const bool _showTrainingOrb = true;
  static const bool _showTrainingStartCard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = riverpod.ProviderScope.containerOf(
        context,
        listen: false,
      ).read(profileProvider);
      profile.loadTrainingDates(context);

      final auth = riverpod.ProviderScope.containerOf(
        context,
        listen: false,
      ).read(authControllerProvider);
      final uid = auth.userId;
      if (uid != null) {
        final container = riverpod.ProviderScope.containerOf(
          context,
          listen: false,
        );
        container.read(settingsProvider).load(uid);
        final gymId = auth.gymCode ?? '';
        container.read(xpProvider).watchStatsDailyXp(gymId, uid);
      }
    });
  }

  Future<void> _openCalendarPopup(
    String userId,
    List<String> trainingDates,
  ) async {
    // Plan-Zuweisungen + Farben nur im Popup laden (nicht im Profil-Header).
    final auth = ref.read(authControllerProvider);
    final gymId = auth.gymCode ?? '';
    final uid = auth.userId;

    List<String> scheduledDates = const [];
    Map<String, Color> scheduledColorsByDate = const {};

    if (uid != null && gymId.isNotEmpty) {
      try {
        final scheduleRepo = ref.read(trainingScheduleRepositoryProvider);
        final planRepo = ref.read(trainingPlanRepositoryProvider);
        final assignments = await scheduleRepo.getAssignmentsForYear(
          userId: uid,
          year: DateTime.now().year,
        );
        final plans = await planRepo.getPlans(gymId: gymId, userId: uid);
        final plansById = {for (final p in plans) p.id: p};
        final colors = <String, Color>{};
        final dateKeys = <String>[];
        for (final a in assignments) {
          dateKeys.add(a.dateKey);
          final plan = plansById[a.planId];
          if (plan != null) {
            colors[a.dateKey] = PlanColorPalette.colorForIndex(
              plan.colorIndex,
              Theme.of(context),
            );
          }
        }
        scheduledDates = dateKeys;
        scheduledColorsByDate = colors;
      } catch (_) {
        // Falls etwas schiefgeht, einfach ohne Farbmarkierungen weitermachen.
        scheduledDates = const [];
        scheduledColorsByDate = const {};
      }
    }

    final selected = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CalendarPopup(
        trainingDates: trainingDates,
        initialYear: DateTime.now().year,
        userId: userId,
        navigateOnTap: false,
        scheduledDates: scheduledDates,
        scheduledColorsByDate: scheduledColorsByDate,
      ),
    );
    if (!mounted || selected == null) {
      return;
    }

    if (uid == null) {
      return;
    }

    final dateKey =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';

    String? assignedPlanName;
    String? assignedPlanId;
    try {
      final scheduleRepo = ref.read(trainingScheduleRepositoryProvider);
      final assignment = await scheduleRepo.getAssignment(
        userId: uid,
        dateKey: dateKey,
      );
      if (assignment != null) {
        assignedPlanId = assignment.planId;
        final planRepo = ref.read(trainingPlanRepositoryProvider);
        final plans = await planRepo.getPlans(gymId: gymId, userId: uid);
        final matchingPlan = plans
            .where((p) => p.id == assignment.planId)
            .toList()
            .cast<TrainingPlan>();
        if (matchingPlan.isNotEmpty) {
          assignedPlanName = matchingPlan.first.name;
        }
      }
    } catch (_) {
      // Bei Fehlern einfach ohne Plan-Namen weitermachen.
      assignedPlanName = null;
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => TrainingDayActionSheet(
        date: selected,
        assignedPlanName: assignedPlanName,
        onOpenDetails: () {
          final args = <String, dynamic>{'userId': userId, 'date': selected};
          if (gymId.isNotEmpty) {
            args['gymId'] = gymId;
          }
          Navigator.of(
            context,
          ).pushNamed(AppRouter.trainingDetails, arguments: args);
        },
        onOpenPlanSelection: () async {
          if (gymId.isEmpty) {
            return;
          }
          try {
            final planRepo = ref.read(trainingPlanRepositoryProvider);
            final plans = await planRepo.getPlans(gymId: gymId, userId: uid);
            if (!mounted) return;
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => PlanSelectionSheet(
                plans: plans,
                currentUserId: uid,
                selectedPlanId: assignedPlanId,
                onClear: assignedPlanId == null
                    ? null
                    : () async {
                        final scheduleRepo = ref.read(
                          trainingScheduleRepositoryProvider,
                        );
                        await scheduleRepo.clearAssignment(
                          userId: uid,
                          dateKey: dateKey,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Plan-Zuweisung für diesen Tag entfernt.',
                            ),
                          ),
                        );
                      },
                onSelect: (plan) async {
                  final scheduleRepo = ref.read(
                    trainingScheduleRepositoryProvider,
                  );
                  await scheduleRepo.setAssignment(
                    userId: uid,
                    dateKey: dateKey,
                    planId: plan.id,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Plan "${plan.name}" für diesen Tag geplant.',
                      ),
                    ),
                  );
                },
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Laden der Pläne: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _handleStartTraining() async {
    final auth = ref.read(authControllerProvider);
    final gymId = auth.gymCode;
    final uid = auth.userId;
    if (uid == null || gymId == null || gymId.isEmpty) {
      return;
    }

    final timerService = ref.read(workoutSessionDurationServiceProvider);
    final isTimerRunning = timerService.isRunning;
    WorkoutDayController workoutController = ref.read(
      workoutDayControllerProvider,
    );

    // Wenn Timer läuft, biete Speichern oder Verwerfen an.
    if (isTimerRunning) {
      final sessions = workoutController.sessionsFor(userId: uid, gymId: gymId);
      final canSave = sessions.any((session) => session.canShowSaveAction);
      final action = await showDialog<_ActiveTrainingAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aktives Training'),
          content: Text(
            canSave
                ? 'Du kannst den Trainingstag jetzt speichern oder komplett verwerfen.'
                : 'Es gibt aktuell nichts zum Speichern. Du kannst den Trainingstag nur verwerfen oder zurückgehen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zurück'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_ActiveTrainingAction.discard),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Verwerfen'),
            ),
            FilledButton(
              onPressed: canSave
                  ? () => Navigator.of(ctx).pop(_ActiveTrainingAction.save)
                  : null,
              child: const Text('Speichern'),
            ),
          ],
        ),
      );

      if (!mounted || action == null) {
        return;
      }

      if (action == _ActiveTrainingAction.save) {
        // Für identisches Verhalten zur WorkoutDay-Page:
        // derselbe Finish-Flow (Bestätigung, offene Sätze, Save, Overlay, Highlights),
        // aber ohne zusätzliche Navigation zurück zur Profilseite.
        final planContext = workoutController.getPlanContext(gymId: gymId);
        await WorkoutFinishFlow.saveAndFinish(
          context: context,
          navigatorKey: navigatorKey,
          controller: workoutController,
          auth: auth,
          settings: ref.read(settingsProvider),
          sessions: sessions,
          fallbackGymId: gymId,
          navigateToHomeProfileOnSuccess: false,
          planId: planContext?.$1,
          planName: planContext?.$2,
        );
        return;
      }

      // Verwerfen: Timer + offene Sessions verwerfen.
      await timerService.discard();
      workoutController.cancelActivePlan(userId: uid, gymId: gymId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trainingstag wurde abgebrochen.')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final scheduleRepo = ref.read(trainingScheduleRepositoryProvider);
    String? planId;
    String? planName;
    TrainingPlan? selectedPlan;
    try {
      final assignment = await scheduleRepo.getAssignment(
        userId: uid,
        dateKey: dateKey,
      );
      if (assignment != null) {
        final planRepo = ref.read(trainingPlanRepositoryProvider);
        final plans = await planRepo.getPlans(gymId: gymId, userId: uid);
        for (final p in plans) {
          if (p.id == assignment.planId) {
            selectedPlan = p;
            planId = p.id;
            planName = p.name;
            break;
          }
        }
      }
    } catch (_) {
      planId = null;
      planName = null;
    }

    Future<void> startFreestyle() async {
      // Falls für heute ein Plan zugewiesen war, wird die Zuweisung
      // beim Wechsel auf Freestyle entfernt, damit der Trainingstage-
      // Kalender den Tag nicht länger als "geplant" markiert.
      try {
        await scheduleRepo.clearAssignment(userId: uid, dateKey: dateKey);
      } catch (_) {
        // Bei Fehlern Freestyle trotzdem starten; Kalendersync ist sekundär.
      }

      final timer = ref.read(workoutSessionDurationServiceProvider);
      await timer.start(uid: uid, gymId: gymId);
      if (!mounted) return;
      // Freestyle-Start: Gym-Tab (Index 0) anzeigen, Workout-Tab ist
      // dennoch sichtbar, aber zunächst ohne aktive Session.
      Navigator.pushNamed(context, AppRouter.home, arguments: 0);
    }

    Future<void> startPlan(TrainingPlan plan) async {
      final controller = workoutController;

      if (plan.exercises.isNotEmpty) {
        for (final item in plan.exercises) {
          final exerciseName = item.name?.isNotEmpty == true ? item.name : null;
          controller.addOrFocusSession(
            gymId: gymId,
            deviceId: item.deviceId,
            exerciseId: item.exerciseId,
            exerciseName: exerciseName,
            userId: uid,
          );
        }
      }

      final effectivePlanId = plan.id;
      if (effectivePlanId.isEmpty) {
        // Fallback: ohne gültige Plan-ID einfach Freestyle starten.
        await startFreestyle();
        return;
      }

      // Plan-Zuweisung für HEUTE aktualisieren, damit der Trainingstage-
      // Kalender sofort die richtige Farbe zeigt (auch wenn heute zuvor
      // ein anderer Plan zugewiesen war oder gar keiner geplant war).
      await scheduleRepo.setAssignment(
        userId: uid,
        dateKey: dateKey,
        planId: effectivePlanId,
      );

      controller.setPlanContext(
        gymId: gymId,
        planId: effectivePlanId,
        planName: plan.name,
        date: now,
      );

      await timerService.start(uid: uid, gymId: gymId);
      if (!mounted) return;

      if (plan.exercises.isNotEmpty) {
        // Plan-Sessions wurden im WorkoutDayController angelegt.
        // Navigiere in den Home-Screen und aktiviere dort den Workout-Tab,
        // der die zuletzt aktive Session öffnet.
        Navigator.pushNamed(context, AppRouter.home, arguments: 2);
      } else {
        Navigator.pushNamed(context, AppRouter.home, arguments: 2);
      }
    }

    Future<void> startPlanned() async {
      if (planId == null || planName == null || selectedPlan == null) {
        await startFreestyle();
        return;
      }
      await startPlan(selectedPlan);
    }

    Future<List<TrainingPlan>> loadAvailablePlans() async {
      final planRepo = ref.read(trainingPlanRepositoryProvider);
      return planRepo.getPlans(gymId: gymId, userId: uid);
    }

    // Start-Dialog je nach Situation:
    // - mit geplantem Plan: "Plan (heute)", "Anderer Plan", "Freestyle"
    // - ohne geplanten Plan: "Plan auswählen", "Freestyle"
    final hasPlannedPlan =
        planId != null && planName != null && selectedPlan != null;
    final result = await showDialog<_TrainingStartDialogResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _TrainingStartDialog(
        planName: planName ?? '',
        hasPlannedPlan: hasPlannedPlan,
        loadPlans: loadAvailablePlans,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result.action) {
      case _TrainingStartAction.startFreestyle:
        await startFreestyle();
        return;
      case _TrainingStartAction.startPlanned:
        await startPlanned();
        return;
      case _TrainingStartAction.startSelectedPlan:
        final plan = result.selectedPlan;
        if (plan == null) {
          return;
        }
        // Explizite Auswahl überschreibt die Tageszuweisung, damit der
        // Kalender sofort den gewählten Plan + Farbe anzeigt.
        await startPlan(plan);
        return;
    }
  }

  void _showAvatarPicker() {
    final auth = ref.read(authControllerProvider);
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: AvatarPicker(
          currentKey: auth.avatarKey,
          onSelect: (key) {
            auth.setAvatarKey(key);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showProfileXpSheet(AuthProvider auth) {
    final xpProv = ref.read(xpProvider);
    final profile = PublicProfile(
      uid: auth.userId ?? '',
      username: auth.userName ?? auth.userEmail ?? 'Tapem',
      primaryGymCode: auth.gymCode,
      avatarKey: auth.avatarKey,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.cardLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.cardLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.cardLg),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: DailyXpCard(
                  profile: profile,
                  level: xpProv.dailyLevel,
                  xpInLevel: xpProv.dailyLevelXp,
                  totalXp: xpProv.statsDailyXp,
                  onAvatarTap: () {
                    // Close the Profile XP Card dialog first? No, keep it open?
                    // User said: "wenn ich ... klicke ... profilbild ... groß ... change button"
                    // If I close the card dialog, the context changes.
                    // The user might expect the flow: Card -> Fullscreen -> (Change) -> Picker -> (Select) -> Back to Fullscreen/Card
                    // Let's keep existing dialog open? But Fullscreen usually covers everything.
                    // Let's close the XP Card dialog? OR open Fullscreen on top.
                    // If we open on top, when we close fullscreen we are back to XP Card. That seems nice.
                    _showFullAvatarWithEdit(
                      profile.avatarKey ?? 'default',
                      profile.primaryGymCode,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullAvatarWithEdit(String currentKey, String? gymId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (ctx) {
        // Use StatefulBuilder if we need to update the image after change without closing
        return StatefulBuilder(
          builder: (context, setState) {
            final path = AvatarCatalog.instance.resolvePathOrFallback(
              currentKey,
              gymId: gymId,
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.asset(path, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  right: 30, // "unten rechts"
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Open Avatar Picker
                        // When user selects, we need to update 'currentKey' here to show new image immediately?
                        // The Profile Screen state updates via riverpod, but this local dialog state needs update too.
                        // Or we just rely on parent rebuild? But we are in a dialog on top of a dialog.
                        // Let's close this Fullscreen dialog, open picker?
                        // User said: "wenn ich den anklicke werden mir erst alle meine verfügbaren angezeigt"

                        // Better flow: Open picker on top. If selected, update state.
                        Navigator.pop(context); // Close fullscreen
                        _showAvatarPicker(); // Open picker
                        // Note: After picking, the user is back to ProfileScreen (XP Card dialog is underneath).
                        // The XP Card dialog will rebuild with new avatar if provider updates.
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ändern',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCoachingSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: riverpod.Consumer(
              builder: (context, ref, _) {
                final relationsAsync = ref.watch(
                  coaching.clientRelationsProvider,
                );
                return relationsAsync.maybeWhen(
                  data: (relations) {
                    final active = relations
                        .where((r) => r.isActive)
                        .toList(growable: false);
                    final pending = relations
                        .where((r) => r.isPending)
                        .toList(growable: false);
                    return _ProfileCoachingSection(
                      activeRelations: active,
                      pendingRelations: pending,
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final neutralAccent =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: BrandModalSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandModalHeader(
                  icon: Icons.logout_rounded,
                  accent: errorColor,
                  title: 'Abmelden?',
                  subtitle: 'Möchtest du dich wirklich abmelden?',
                  onClose: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(height: 16),
                BrandModalOptionCard(
                  title: 'Abmelden',
                  subtitle: 'Sitzung beenden und zum Login wechseln',
                  icon: Icons.logout_rounded,
                  accent: errorColor,
                  highlighted: true,
                  trailing: Icon(
                    Icons.warning_amber_rounded,
                    color: errorColor.withOpacity(0.9),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await ref.read(authControllerProvider).logout();
                    if (!mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRouter.auth, (route) => false);
                  },
                ),
                const SizedBox(height: 10),
                BrandModalOptionCard(
                  title: 'Abbrechen',
                  subtitle: 'Im Profil bleiben',
                  icon: Icons.close_rounded,
                  accent: neutralAccent,
                  trailing: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(profileProvider);
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final xp = ref.watch(xpProvider);
    final userId = auth.userId ?? '';
    final isActiveTraining = ref
        .watch(workoutSessionDurationServiceProvider)
        .isRunning;
    const avatarSize = 52.0;

    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    Widget buildBody() {
      if (prov.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (prov.error != null) {
        return Center(child: Text('Fehler: ${prov.error}'));
      }
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.profileTrainingDaysHeading,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ) ??
                  TextStyle(fontWeight: FontWeight.bold, color: brandColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openCalendarPopup(userId, prov.trainingDates),
              child: Calendar(
                trainingDates: prov.trainingDates,
                showNavigation: false,
                year: DateTime.now().year,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_showTrainingOrb)
              Expanded(
                child: Center(
                  child: _TrainingStartOrb(
                    brandColor: brandColor,
                    isActive: isActiveTraining,
                    onTap: _handleStartTraining,
                  ),
                ),
              ),
            if (_showTrainingOrb) const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        foregroundColor: brandColor,
        automaticallyImplyLeading: false,
        leadingWidth: avatarSize + AppSpacing.md * 2,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Tooltip(
              message: loc.profileChangeAvatar,
              child: Semantics(
                button: true,
                label: loc.profileChangeAvatar,
                child: GestureDetector(
                  onTap: () => _showProfileXpSheet(auth),
                  child: Builder(
                    builder: (context) {
                      final gymId = auth.gymCode;
                      final path = AvatarCatalog.instance.resolvePathOrFallback(
                        auth.avatarKey,
                        gymId: gymId,
                      );
                      final image = Image.asset(
                        path,
                        errorBuilder: (_, __, ___) {
                          if (kDebugMode) {
                            debugPrint('[Avatar] failed to load $path');
                          }
                          return const Icon(Icons.person);
                        },
                      );
                      return DailyXpAvatar(
                        image: image.image,
                        size: avatarSize,
                        xp: xp.dailyLevelXp,
                        level: xp.dailyLevel,
                        strokeWidth: 5.0,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          if (enableFriends)
            riverpod.Consumer(
              builder: (context, ref, _) {
                final alerts = ref.watch(friendAlertsProvider);

                return IconButton(
                  icon: Stack(
                    children: [
                      const BrandGradientIcon(Icons.group),
                      if (alerts.showBadge)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  tooltip: loc.friends_title,
                  onPressed: () {
                    Navigator.push(context, FriendsHomeScreen.route());
                  },
                );
              },
            ),
          if (ref.watch(settingsProvider).creatineEnabled)
            IconButton(
              icon: const BrandGradientIcon(Icons.medication),
              tooltip: loc.creatineTitle,
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.creatine);
              },
            ),
          IconButton(
            icon: const BrandGradientIcon(Icons.settings),
            tooltip: loc.settingsIconTooltip,
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.settings);
            },
          ),
          IconButton(
            icon: const BrandGradientIcon(Icons.logout),
            tooltip: loc.logoutTooltip,
            onPressed: () => _showLogoutConfirmation(),
          ),
        ],
      ),
      body: DefaultTextStyle.merge(
        style: TextStyle(color: brandColor),
        child: buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ref.watch(settingsProvider).coachingProfileEnabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ProfileCoachingButton(onTap: _showCoachingSheet),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ProfileProgressButton(
                              compact: true,
                              compactTitle: 'Prog',
                              onTap: () {
                                final cb = widget.onOpenProgress;
                                if (cb != null) {
                                  cb();
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.progress,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ProfileHubButton(
                              compact: true,
                              compactTitle: 'Hub',
                              onStatsTap: () {
                                final cb = widget.onOpenDiscoverStats;
                                if (cb != null) {
                                  cb();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfileStatsScreen(),
                                    ),
                                  );
                                }
                              },
                              onCommunityTap: () {
                                final cb = widget.onOpenDiscoverCommunity;
                                if (cb != null) {
                                  cb();
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.community,
                                  );
                                }
                              },
                              onSurveysTap: () {
                                final cb = widget.onOpenDiscoverSurveys;
                                if (cb != null) {
                                  cb();
                                } else {
                                  final gymId = ref
                                      .read(gymProvider)
                                      .currentGymId;
                                  final userId =
                                      ref.read(authControllerProvider).userId ??
                                      '';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SurveyVoteScreen(
                                        gymId: gymId,
                                        userId: userId,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileShortcutButton(
                              compact: true,
                              icon: Icons.restaurant_rounded,
                              title: 'Food',
                              onTap: () {
                                final cb = widget.onOpenNutrition;
                                if (cb != null) {
                                  cb();
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.nutrition,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ProfileShortcutButton(
                              compact: true,
                              icon: Icons.event_note_rounded,
                              title: 'Plan',
                              onTap: () {
                                final cb = widget.onOpenPlan;
                                if (cb != null) {
                                  cb();
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.planOverview,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_showTrainingStartCard)
                  Builder(
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: GestureDetector(
                          onTap: _handleStartTraining,
                          child: _TrainingStartCard(
                            brandColor: brandColor,
                            isActive: isActiveTraining,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingStartCard extends StatelessWidget {
  const _TrainingStartCard({required this.brandColor, required this.isActive});

  final Color brandColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = isActive ? 'Training beenden' : 'Training starten';
    final subtitle = isActive
        ? 'Speichern oder verwerfen'
        : 'Plan oder Freestyle-Training starten';

    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandColor.withOpacity(0.10), brandColor.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    brandColor.withOpacity(0.95),
                    brandColor.withOpacity(0.4),
                    brandColor.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  center: Alignment.center,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.85),
                ),
                child: Center(
                  child: Icon(
                    isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                    color: brandColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withOpacity(0.22),
                    brandColor.withOpacity(0.02),
                  ],
                  center: Alignment.topLeft,
                  radius: 1.0,
                ),
                border: Border.all(
                  color: brandColor.withOpacity(0.4),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_outward_rounded,
                color: brandColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TrainingStartAction { startFreestyle, startPlanned, startSelectedPlan }

class _TrainingStartDialogResult {
  const _TrainingStartDialogResult._(this.action, [this.selectedPlan]);

  const _TrainingStartDialogResult.freestyle()
    : this._(_TrainingStartAction.startFreestyle);

  const _TrainingStartDialogResult.planned()
    : this._(_TrainingStartAction.startPlanned);

  const _TrainingStartDialogResult.selectedPlan(TrainingPlan plan)
    : this._(_TrainingStartAction.startSelectedPlan, plan);

  final _TrainingStartAction action;
  final TrainingPlan? selectedPlan;
}

enum _TrainingStartDialogMode { startOptions, planPicker }

class _TrainingStartDialog extends StatefulWidget {
  const _TrainingStartDialog({
    required this.planName,
    required this.hasPlannedPlan,
    required this.loadPlans,
  });

  final String planName;
  final bool hasPlannedPlan;
  final Future<List<TrainingPlan>> Function() loadPlans;

  @override
  State<_TrainingStartDialog> createState() => _TrainingStartDialogState();
}

class _TrainingStartDialogState extends State<_TrainingStartDialog> {
  _TrainingStartDialogMode _mode = _TrainingStartDialogMode.startOptions;
  bool _isLoadingPlans = false;
  List<TrainingPlan>? _plans;
  String? _plansError;

  Future<void> _openPlanPicker() async {
    setState(() => _mode = _TrainingStartDialogMode.planPicker);
    if (_plans != null || _isLoadingPlans) {
      return;
    }
    await _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });
    try {
      final loaded = await widget.loadPlans();
      if (!mounted) return;
      setState(() => _plans = loaded);
    } catch (_) {
      if (!mounted) return;
      setState(() => _plansError = 'Fehler beim Laden der Pläne.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlans = false);
      }
    }
  }

  void _backToStartOptions() {
    setState(() => _mode = _TrainingStartDialogMode.startOptions);
  }

  double _resolveDialogWidth(double maxDialogWidth) {
    if (_mode != _TrainingStartDialogMode.planPicker) {
      return maxDialogWidth;
    }

    final count = math.max(1, _plans?.length ?? 1);
    final visibleSlots = math.min(5, count);
    const baseWidth = 132.0;
    const perPlanWidth = 88.0;
    final desired = baseWidth + (visibleSlots * perPlanWidth);
    return desired.clamp(280.0, maxDialogWidth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.secondary;
    final maxDialogWidth = (MediaQuery.of(context).size.width - 48).clamp(
      280.0,
      640.0,
    );
    final dialogWidth = _resolveDialogWidth(maxDialogWidth);
    final isPlanPicker = _mode == _TrainingStartDialogMode.planPicker;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: dialogWidth,
        child: BrandModalSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandModalHeader(
                icon: isPlanPicker
                    ? Icons.view_list_rounded
                    : Icons.play_arrow_rounded,
                accent: accent,
                title: isPlanPicker
                    ? (widget.hasPlannedPlan
                          ? 'Anderen Plan auswählen'
                          : 'Plan auswählen')
                    : 'Was steht heute an?',
                subtitle: isPlanPicker
                    ? 'Wähle einen Trainingsplan'
                    : 'Wähle deinen Startmodus',
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: isPlanPicker
                    ? _TrainingPlanPickerContent(
                        key: const ValueKey('plan-picker'),
                        plans: _plans,
                        isLoading: _isLoadingPlans,
                        errorText: _plansError,
                        accent: accent,
                        onRetry: _loadPlans,
                        onBack: _backToStartOptions,
                        onSelectPlan: (plan) {
                          Navigator.pop(
                            context,
                            _TrainingStartDialogResult.selectedPlan(plan),
                          );
                        },
                      )
                    : _TrainingStartOptionsContent(
                        key: const ValueKey('start-options'),
                        hasPlannedPlan: widget.hasPlannedPlan,
                        planName: widget.planName,
                        accent: accent,
                        onStartPlanned: widget.hasPlannedPlan
                            ? () {
                                Navigator.pop(
                                  context,
                                  const _TrainingStartDialogResult.planned(),
                                );
                              }
                            : null,
                        onStartFreestyle: () {
                          Navigator.pop(
                            context,
                            const _TrainingStartDialogResult.freestyle(),
                          );
                        },
                        onOpenPlanPicker: _openPlanPicker,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingStartOptionsContent extends StatelessWidget {
  const _TrainingStartOptionsContent({
    super.key,
    required this.hasPlannedPlan,
    required this.planName,
    required this.accent,
    required this.onStartFreestyle,
    required this.onOpenPlanPicker,
    this.onStartPlanned,
  });

  final bool hasPlannedPlan;
  final String planName;
  final Color accent;
  final VoidCallback onStartFreestyle;
  final VoidCallback onOpenPlanPicker;
  final VoidCallback? onStartPlanned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPlannedPlan)
          _TrainingStartOptionCard(
            title: 'Plan ($planName)',
            subtitle: 'Geplanter Plan für heute',
            icon: Icons.play_arrow_rounded,
            accent: accent,
            onTap: onStartPlanned,
            highlighted: true,
          ),
        if (hasPlannedPlan) const SizedBox(height: 10),
        _TrainingStartOptionCard(
          title: 'Freestyle',
          subtitle: 'Ohne Plan starten',
          icon: Icons.fitness_center_outlined,
          accent: accent,
          onTap: onStartFreestyle,
        ),
        const SizedBox(height: 10),
        _TrainingStartOptionCard(
          title: hasPlannedPlan ? 'Anderer Plan' : 'Plan auswählen',
          subtitle: 'Trainingsplan auswählen',
          icon: Icons.view_list_rounded,
          accent: accent,
          onTap: onOpenPlanPicker,
        ),
      ],
    );
  }
}

class _TrainingPlanPickerContent extends StatelessWidget {
  const _TrainingPlanPickerContent({
    super.key,
    required this.plans,
    required this.isLoading,
    required this.errorText,
    required this.accent,
    required this.onRetry,
    required this.onBack,
    required this.onSelectPlan,
  });

  final List<TrainingPlan>? plans;
  final bool isLoading;
  final String? errorText;
  final Color accent;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final ValueChanged<TrainingPlan> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorText != null) {
      return Column(
        key: const ValueKey('plans-error'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorText!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Zurück'),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut laden'),
              ),
            ],
          ),
        ],
      );
    }

    final availablePlans = plans ?? const <TrainingPlan>[];
    if (availablePlans.isEmpty) {
      return Column(
        key: const ValueKey('plans-empty'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Du hast aktuell keine Trainingspläne.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Zurück'),
          ),
        ],
      );
    }

    final visibleCards = math.min(5, availablePlans.length);
    const spacing = 10.0;
    final isCupertinoLike =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final scrollPhysics = isCupertinoLike
        ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const ClampingScrollPhysics();
    final showScrollHint = availablePlans.length > visibleCards;

    return LayoutBuilder(
      key: const ValueKey('plans-list'),
      builder: (context, constraints) {
        final widthForCards = constraints.maxWidth;
        final rawCardWidth =
            (widthForCards - spacing * (visibleCards - 1)) / visibleCards;
        final minCardWidth = isCupertinoLike ? 72.0 : 76.0;
        final maxCardWidth = isCupertinoLike ? 156.0 : 168.0;
        final cardWidth = rawCardWidth.clamp(minCardWidth, maxCardWidth);
        final compactCards = cardWidth < 92.0;
        final cardHeight = compactCards ? 120.0 : 132.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Zurück'),
            ),
            const SizedBox(height: 6),
            if (showScrollHint)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Weitere Pläne per Wischen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.62),
                    fontSize: 11.5,
                  ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: scrollPhysics,
              child: Row(
                children: [
                  for (var i = 0; i < availablePlans.length; i++) ...[
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _TrainingPlanQuickPickCard(
                        plan: availablePlans[i],
                        accent: accent,
                        compact: compactCards,
                        onTap: () => onSelectPlan(availablePlans[i]),
                      ),
                    ),
                    if (i != availablePlans.length - 1)
                      const SizedBox(width: spacing),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrainingStartOptionCard extends StatelessWidget {
  const _TrainingStartOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return BrandModalOptionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
      accent: accent,
      highlighted: highlighted,
    );
  }
}

class _TrainingPlanQuickPickCard extends StatelessWidget {
  const _TrainingPlanQuickPickCard({
    required this.plan,
    required this.accent,
    required this.compact,
    required this.onTap,
  });

  final TrainingPlan plan;
  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planColor = PlanColorPalette.colorForIndex(plan.colorIndex, theme);
    final exerciseCount = plan.exercises.length;
    final subtitle =
        '$exerciseCount ${exerciseCount == 1 ? 'Übung' : 'Übungen'}';
    final isCoachPlan = plan.coachId != null && plan.coachId!.isNotEmpty;

    return BrandInteractiveCard(
      onTap: onTap,
      padding: compact
          ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
          : const EdgeInsets.fromLTRB(10, 10, 10, 10),
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      showShadow: false,
      enableScaleAnimation: true,
      backgroundColor: Colors.white.withOpacity(0.04),
      restingBorderColor: theme.colorScheme.onSurface.withOpacity(0.09),
      activeBorderColor: accent.withOpacity(0.45),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [planColor, planColor.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.view_list_rounded,
              color: Colors.black,
              size: compact ? 14 : 16,
            ),
          ),
          SizedBox(height: compact ? 7 : 9),
          Text(
            plan.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12.5 : 13.5,
              height: 1.15,
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontSize: compact ? 10.3 : 11.2,
              height: 1.1,
            ),
          ),
          if (isCoachPlan) ...[
            SizedBox(height: compact ? 5 : 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 5 : 6,
                vertical: compact ? 1.5 : 2,
              ),
              decoration: BoxDecoration(
                color: planColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Coach',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: planColor.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainingStartOrb extends StatelessWidget {
  const _TrainingStartOrb({
    required this.brandColor,
    required this.isActive,
    required this.onTap,
  });

  final Color brandColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.42;
    final outerSize = size.clamp(128.0, 180.0);
    final innerSize = outerSize - 14;

    return Semantics(
      button: true,
      label: isActive ? 'Training beenden' : 'Training starten',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: outerSize,
          height: outerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                brandColor.withOpacity(0.95),
                brandColor.withOpacity(0.4),
                brandColor.withOpacity(0.95),
              ],
              stops: const [0.0, 0.5, 1.0],
              center: Alignment.center,
            ),
            boxShadow: [
              BoxShadow(
                color: brandColor.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.85),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: outerSize * 0.32,
                  color: brandColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCoachingSection extends riverpod.ConsumerWidget {
  const _ProfileCoachingSection({
    required this.activeRelations,
    required this.pendingRelations,
  });

  final List<CoachClientRelation> activeRelations;
  final List<CoachClientRelation> pendingRelations;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

    final active = activeRelations.isNotEmpty ? activeRelations.first : null;
    final invitesAsync = ref.watch(coach_invites.clientCoachInvitesProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coaching',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: brandColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (active != null)
            FutureBuilder<String>(
              future: ref
                  .read(
                    coaching.coachDisplayNameProvider(active.coachId).future,
                  )
                  .catchError((_) => 'Coach'),
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Coach';
                return Row(
                  children: [
                    Icon(Icons.school, color: brandColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dein Coach',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(name, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          else
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Du hast aktuell keinen Coach.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          if (pendingRelations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              pendingRelations.length == 1
                  ? '1 ausstehende Coaching-Anfrage'
                  : '${pendingRelations.length} ausstehende Coaching-Anfragen',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (active == null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelectCoachScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Coach auswählen'),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InviteExternalCoachScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Externen Coach einladen'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          invitesAsync.when(
            data: (invites) {
              final pendingInvites = invites.where((i) => i.isPending).toList();
              if (pendingInvites.isEmpty) {
                return Text(
                  loc.profileTrainingDaysHeading,
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ) ??
                      TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pendingInvites.length == 1
                        ? '1 offene Einladung an einen externen Coach'
                        : '${pendingInvites.length} offene Einladungen an externe Coaches',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    loc.profileTrainingDaysHeading,
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ) ??
                        TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                  ),
                ],
              );
            },
            loading: () => Text(
              loc.profileTrainingDaysHeading,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ) ??
                  TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
            ),
            error: (_, __) => Text(
              loc.profileTrainingDaysHeading,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ) ??
                  TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.currentKey,
    required this.onSelect,
  });

  final String currentKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authControllerProvider);
    final inventory = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(avatarInventoryProvider);
    final theme = Theme.of(context);
    return StreamBuilder<List<AvatarInventoryEntry>>(
      stream: inventory.inventory(auth.userId ?? ''),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AvatarInventoryEntry>[];
        final currentGym = auth.gymCode;
        final Map<String, AvatarInventoryEntry> map = {};
        for (final item in items) {
          final norm = AvatarAssets.normalizeKey(
            item.key,
            currentGymId: currentGym,
          );
          map[norm] = AvatarInventoryEntry(
            key: norm,
            source: item.source,
            createdAt: item.createdAt,
          );
        }
        for (final d in [
          AvatarInventoryEntry(
            key: AvatarKeys.globalDefault,
            source: 'global_default',
          ),
          AvatarInventoryEntry(
            key: AvatarKeys.globalDefault2,
            source: 'global_default',
          ),
        ]) {
          map.putIfAbsent(d.key, () => d);
        }
        final entries = map.values.toList()
          ..sort((a, b) {
            if (a.source == 'global_default' && b.source != 'global_default') {
              return -1;
            }
            if (a.source != 'global_default' && b.source == 'global_default') {
              return 1;
            }
            final aTime = a.createdAt?.toDate() ?? DateTime(1970);
            final bTime = b.createdAt?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
        final keys = entries.map((e) => e.key).toList();
        return SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final selected = key == currentKey;
              final label = 'Avatar ${index + 1}';
              final avatar = Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final gymId = auth.gymCode;
                        final path = AvatarCatalog.instance
                            .resolvePathOrFallback(key, gymId: gymId);
                        final image = Image.asset(
                          path,
                          errorBuilder: (_, __, ___) {
                            if (kDebugMode) {
                              debugPrint('[Avatar] failed to load $path');
                            }
                            return const Icon(Icons.person);
                          },
                        );
                        return CircleAvatar(
                          radius: 40,
                          backgroundImage: image.image,
                        );
                      },
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                ],
              );
              final child = avatar;
              return Tooltip(
                message: label,
                child: Semantics(
                  label: label,
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    onTap: () => onSelect(key),
                    child: child,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
