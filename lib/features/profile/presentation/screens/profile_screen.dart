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
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';

const bool enableFriends = true;

class ProfileScreen extends riverpod.ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  riverpod.ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends riverpod.ConsumerState<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = riverpod.ProviderScope.containerOf(context, listen: false)
          .read(profileProvider);
      profile.loadTrainingDates(context);

      final auth =
          riverpod.ProviderScope.containerOf(context, listen: false)
              .read(authControllerProvider);
      final uid = auth.userId;
      if (uid != null) {
        final container =
            riverpod.ProviderScope.containerOf(context, listen: false);
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
        final plansById = {
          for (final p in plans) p.id: p,
        };
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
      final scheduleRepo =
          ref.read(trainingScheduleRepositoryProvider);
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

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => TrainingDayActionSheet(
        date: selected,
        assignedPlanName: assignedPlanName,
        onOpenDetails: () {
          final args = <String, dynamic>{
            'userId': userId,
            'date': selected,
          };
          if (gymId.isNotEmpty) {
            args['gymId'] = gymId;
          }
          Navigator.of(context).pushNamed(
            AppRouter.trainingDetails,
            arguments: args,
          );
        },
        onOpenPlanSelection: () async {
          if (gymId.isEmpty) {
            return;
          }
          try {
            final planRepo = ref.read(trainingPlanRepositoryProvider);
            final plans = await planRepo.getPlans(
              gymId: gymId,
              userId: uid,
            );
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
                        final scheduleRepo =
                            ref.read(trainingScheduleRepositoryProvider);
                        await scheduleRepo.clearAssignment(
                          userId: uid,
                          dateKey: dateKey,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Plan-Zuweisung für diesen Tag entfernt.'),
                          ),
                        );
                      },
                onSelect: (plan) async {
                  final scheduleRepo =
                      ref.read(trainingScheduleRepositoryProvider);
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
              SnackBar(
                content: Text('Fehler beim Laden der Pläne: $e'),
              ),
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

    final timerService =
        ref.read(workoutSessionDurationServiceProvider);
    final isTimerRunning = timerService.isRunning;
    WorkoutDayController workoutController =
        ref.read(workoutDayControllerProvider);

    // Wenn Timer läuft, biete explizites Stoppen / Abbrechen an.
    if (isTimerRunning) {
      final theme = Theme.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Trainingstag abbrechen?'),
          content: const Text(
            'Der aktuelle Trainingstag wird verworfen. '
            'Alle noch nicht gespeicherten Trainingsdaten gehen verloren.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Zurück'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Training stoppen'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }

      // 1) Timer verwerfen
      await timerService.discard();

      // 2) Alle offenen Sessions für diesen User/Gym schließen
      workoutController.cancelActivePlan(
        userId: uid,
        gymId: gymId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trainingstag wurde abgebrochen.'),
          ),
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
        final planRepo =
            ref.read(trainingPlanRepositoryProvider);
        final plans = await planRepo.getPlans(
          gymId: gymId,
          userId: uid,
        );
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
        await scheduleRepo.clearAssignment(
          userId: uid,
          dateKey: dateKey,
        );
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
          final exerciseName =
              item.name?.isNotEmpty == true ? item.name : null;
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

    Future<void> startOtherPlan() async {
      try {
        final planRepo = ref.read(trainingPlanRepositoryProvider);
        final plans = await planRepo.getPlans(
          gymId: gymId,
          userId: uid,
        );
        if (!mounted) return;
        if (plans.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Du hast aktuell keine Trainingspläne.'),
            ),
          );
          return;
        }

        final theme = Theme.of(context);
        final chosen = await showModalBottomSheet<TrainingPlan>(
          context: context,
          builder: (bottomCtx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Anderen Plan auswählen',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final p in plans)
                  Builder(
                    builder: (_) {
                      final color = PlanColorPalette.colorForIndex(
                        p.colorIndex,
                        theme,
                      );
                      final isCoachPlan = p.coachId != null;
                      final exerciseCount = p.exercises.length;
                      final subtitle =
                          '$exerciseCount ${exerciseCount == 1 ? 'Übung' : 'Übungen'}';
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.view_list_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isCoachPlan)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Coach-Plan',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: color.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                        onTap: () => Navigator.pop(bottomCtx, p),
                      );
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );

        if (!mounted || chosen == null) {
          return;
        }

        // Wenn der Nutzer explizit einen anderen Plan (B) für heute startet,
        // überschreiben wir damit auch direkt die bestehende Tageszuweisung,
        // sodass der Kalender unmittelbar Plan B (inkl. Farbe) zeigt.
        await startPlan(chosen);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Laden der Pläne: $e',
            ),
          ),
        );
      }
    }

    // Bottom-Sheet je nach Situation:
    // - mit geplantem Plan: "Plan (heute)", "Anderer Plan", "Freestyle"
    // - ohne geplanten Plan: "Plan auswählen", "Freestyle"
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final accent = theme.colorScheme.primary;

        final hasPlannedPlan =
            planId != null && planName != null && selectedPlan != null;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              if (hasPlannedPlan)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: accent.withOpacity(0.12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        child: const Icon(Icons.play_arrow_rounded),
                      ),
                      title: Text(
                        'Plan ($planName)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      subtitle: Text(
                        'Geplanter Plan für heute',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        startPlanned();
                      },
                    ),
                  ),
                ),
              if (hasPlannedPlan) const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.fitness_center_outlined),
                title: const Text('Freestyle'),
                onTap: () {
                  Navigator.pop(ctx);
                  startFreestyle();
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_list_rounded),
                title: Text(
                  hasPlannedPlan ? 'Anderer Plan' : 'Plan auswählen',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  startOtherPlan();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
                    Navigator.pop(dialogContext);
                    _showAvatarPicker();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
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
                final relationsAsync =
                    ref.watch(coaching.clientRelationsProvider);
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
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      brandColor.withOpacity(0.1),
                      brandColor.withOpacity(0.02),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Abmelden?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Möchtest du dich wirklich abmelden?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(authControllerProvider).logout();
                          if (!mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRouter.auth,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Abmelden',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
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
    const avatarSize = 44.0;

    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

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
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ) ??
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.sm),
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
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
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
                  child: Builder(builder: (context) {
                    final gymId = auth.gymCode;
                    final path = AvatarCatalog.instance
                        .resolvePathOrFallback(auth.avatarKey,
                            gymId: gymId);
                    final image =
                        Image.asset(path, errorBuilder: (_, __, ___) {
                      if (kDebugMode) {
                        debugPrint('[Avatar] failed to load $path');
                      }
                      return const Icon(Icons.person);
                    });
                    return DailyXpAvatar(
                      image: image.image,
                      size: avatarSize,
                      xp: xp.dailyLevelXp,
                      level: xp.dailyLevel,
                    );
                  }),
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
                final chatUnread = ref.watch(chatUnreadProvider);
                final hasUnreadMessages = chatUnread.valueOrNull?.hasUnread ?? false;
                final showBadge = alerts.showBadge || hasUnreadMessages;

                return IconButton(
                  icon: Stack(
                    children: [
                      const BrandGradientIcon(Icons.group),
                      if (showBadge)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child:
                              CircleAvatar(radius: 4, backgroundColor: Colors.red),
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
                    child: ProfileCoachingButton(
                      onTap: _showCoachingSheet,
                    ),
                  ),
                ProfileHubButton(
                  onStatsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileStatsScreen(),
                      ),
                    );
                  },
                  onCommunityTap: () {
                    Navigator.pushNamed(context, AppRouter.community);
                  },
                  onSurveysTap: () {
                    final gymId = ref.read(gymProvider).currentGymId;
                    final userId =
                        ref.read(authControllerProvider).userId ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurveyVoteScreen(
                          gymId: gymId,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // Training starten / stoppen – immer ganz unten
                Builder(
                  builder: (context) {
                    final timerService =
                        ref.watch(workoutSessionDurationServiceProvider);
                    final isActiveTraining = timerService.isRunning;
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
  const _TrainingStartCard({
    required this.brandColor,
    required this.isActive,
  });

  final Color brandColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = isActive ? 'Training stoppen' : 'Training starten';
    final subtitle = isActive
        ? 'Aktiven Trainingstag abbrechen'
        : 'Plan oder Freestyle-Training starten';

    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandColor.withOpacity(0.10),
            brandColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
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
                    isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
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
    final invitesAsync =
        ref.watch(coach_invites.clientCoachInvitesProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
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
                    coaching.coachDisplayNameProvider(active.coachId)
                        .future,
                  )
                  .catchError((_) => 'Coach'),
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Coach';
                return Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: brandColor,
                    ),
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
                          Text(
                            name,
                            style: theme.textTheme.bodyMedium,
                          ),
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
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.7),
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
                          builder: (_) =>
                              const InviteExternalCoachScreen(),
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
              final pendingInvites =
                  invites.where((i) => i.isPending).toList();
              if (pendingInvites.isEmpty) {
                return Text(
                  loc.profileTrainingDaysHeading,
                  style: theme.textTheme.bodySmall?.copyWith(
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
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    loc.profileTrainingDaysHeading,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5),
                        ) ??
                        TextStyle(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5),
                          fontSize: 12,
                        ),
                  ),
                ],
              );
            },
            loading: () => Text(
              loc.profileTrainingDaysHeading,
              style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.5),
                  ) ??
                  TextStyle(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
            ),
            error: (_, __) => Text(
              loc.profileTrainingDaysHeading,
              style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.5),
                  ) ??
                  TextStyle(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.5),
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
    final auth = riverpod.ProviderScope.containerOf(context, listen: false)
        .read(authControllerProvider);
    final inventory =
        riverpod.ProviderScope.containerOf(context, listen: false)
            .read(avatarInventoryProvider);
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
              key: AvatarKeys.globalDefault, source: 'global_default'),
          AvatarInventoryEntry(
              key: AvatarKeys.globalDefault2, source: 'global_default'),
        ]) {
          map.putIfAbsent(d.key, () => d);
        }
        final entries = map.values.toList()
          ..sort((a, b) {
            if (a.source == 'global_default' &&
                b.source != 'global_default') {
              return -1;
            }
            if (a.source != 'global_default' &&
                b.source == 'global_default') {
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
                    child: Builder(builder: (context) {
                      final gymId = auth.gymCode;
                      final path = AvatarCatalog.instance.resolvePathOrFallback(
                        key,
                        gymId: gymId,
                      );
                      final image = Image.asset(path, errorBuilder:
                          (_, __, ___) {
                        if (kDebugMode) {
                          debugPrint('[Avatar] failed to load $path');
                        }
                        return const Icon(Icons.person);
                      });
                      return CircleAvatar(
                        radius: 40,
                        backgroundImage: image.image,
                      );
                    }),
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
