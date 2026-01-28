// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/deals/presentation/screens/deals_screen.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_overview_screen.dart';
import 'package:tapem/features/coaching/presentation/screens/coaching_home_screen.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_tab_navigator.dart';
import 'package:tapem/features/auth/presentation/widgets/username_dialog.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/timer/timer_app_bar_title.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart'
    as wsds;
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/device/presentation/screens/workout_day_screen.dart';
import 'package:tapem/features/device/presentation/widgets/workout_day_table_card.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;
  _HomeTabId? _lastTabId;

  List<_TabInfo> _buildTabs(BuildContext context) {
    final gymProv = ref.watch(gymProvider);
    final gymId = gymProv.currentGymId;
    final devices = gymProv.devices.where((d) => !d.isMulti).toList();
    final deviceId = devices.isNotEmpty ? devices.first.uid : '';
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final wsds.WorkoutSessionDurationService timerService =
        ref.watch(workoutSessionDurationServiceProvider);
    final WorkoutDayController workoutController =
        ref.read(workoutDayControllerProvider);

    WorkoutDaySession? activeWorkoutSession;
    if (auth.userId != null) {
      final activeGymId = auth.gymCode ?? gymId;
      if (activeGymId.isNotEmpty) {
        final sessions = workoutController.sessionsFor(
          userId: auth.userId!,
          gymId: activeGymId,
        );
        if (sessions.isNotEmpty) {
          activeWorkoutSession = sessions.last;
        }
      }
    }

    final tabs = <_TabInfo>[
      _TabInfo(
        id: _HomeTabId.gym,
        page: const GymScreen(key: PageStorageKey('Gym')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.fitness_center),
          label: loc.gymTitle,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.profile,
        page: const ProfileScreen(key: PageStorageKey('Profile')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: loc.profileTitle,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.nutrition,
        // Eigenes Navigator-Stack für Ernährung, damit BottomTab sichtbar bleibt
        page: const NutritionTabNavigator(key: PageStorageKey('NutritionTab')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.restaurant),
          label: loc.homeTabNutrition,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.report,
        page: const ReportScreen(key: PageStorageKey('Report')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.insert_chart),
          label: loc.reportTitle,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.admin,
        page: const AdminDashboardScreen(key: PageStorageKey('Admin')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          label: loc.homeTabAdmin,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.rank,
        page: RankScreen(
            key: const PageStorageKey('Rank'),
            gymId: gymId,
            deviceId: deviceId),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.leaderboard),
          label: loc.homeTabRank,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.deals,
        page: const DealsScreen(key: PageStorageKey('Deals')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.local_offer),
          label: loc.homeTabDeals,
        ),
      ),
      _TabInfo(
        id: _HomeTabId.plan,
        page: const PlanOverviewScreen(key: PageStorageKey('Plaene')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.event_note),
          label: loc.homeTabPlans,
        ),
      ),
    ];

    // Workout-Tab anzeigen, sobald der globale Workout-Timer läuft.
    // Wenn bereits Sessions existieren, wird die zuletzt aktive Session
    // geöffnet. Andernfalls wird ein "leerer" Workout-Tag mit einem
    // Fallback-Gerät gestartet (sofern vorhanden).
    if (timerService.isRunning) {
      // Wenn eine aktive Session existiert, diese im Workout-Tab öffnen.
      // Ansonsten eine komplett leere Workout-Seite anzeigen, bis der Nutzer
      // über Gym/NFC eine Übung auswählt.
      Widget workoutPage;
      if (activeWorkoutSession != null) {
        final planContext = workoutController.getPlanContext(
          gymId: activeWorkoutSession.gymId,
        );
        workoutPage = WorkoutDayScreen(
          key: const PageStorageKey('Workout'),
          gymId: activeWorkoutSession.gymId,
          deviceId: activeWorkoutSession.deviceId,
          exerciseId: activeWorkoutSession.exerciseId,
          planId: planContext?.$1,
          planName: planContext?.$2,
          sessionBuilder: buildWorkoutDayTableSessionCard,
        );
      } else {
        workoutPage = const _EmptyWorkoutScreen();
      }

      final workoutTab = _TabInfo(
        id: _HomeTabId.workout,
        page: workoutPage,
        item: const BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Workout',
        ),
      );

      const insertIndex = 2; // Nach Gym & Profil
      if (insertIndex >= 0 && insertIndex <= tabs.length) {
        tabs.insert(insertIndex, workoutTab);
      } else {
        tabs.add(workoutTab);
      }
    }

    if (auth.isCoach) {
      tabs.add(
        _TabInfo(
          id: _HomeTabId.coaching,
          page: const CoachingHomeScreen(
            key: PageStorageKey('Coaching'),
          ),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Coaching',
          ),
        ),
      );
    }

    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    debugPrint('[Home] initState initialIndex=${widget.initialIndex}');
    // Nach Login Gym laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = ref.read(authControllerProvider);
      debugPrint('[Tabs] role=${authProv.role}, isAdmin=${authProv.isAdmin}, restricted=${FF.limitTabsForMembers}');
      final gymProv = ref.read(gymProvider);
      final code = authProv.gymCode;
      if (code != null && code.isNotEmpty) {
        gymProv.loadGymData(code);
      }
      if (authProv.userName == null || authProv.userName!.isEmpty) {
        showUsernameDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final isAdmin = auth.isAdmin;
    final isGuest = auth.isGuest;
    final allTabs = _buildTabs(context);
    const restrictedTabIds = {
      _HomeTabId.gym,
      _HomeTabId.profile,
      _HomeTabId.nutrition,
      _HomeTabId.workout,
      _HomeTabId.rank,
      _HomeTabId.deals,
      _HomeTabId.plan,
      _HomeTabId.coaching,
    };
    final tabs = isGuest
        ? allTabs
            .where((tab) => tab.id == _HomeTabId.gym)
            .toList(growable: false)
        : (FF.limitTabsForMembers && !isAdmin)
            ? allTabs
                .where((tab) => restrictedTabIds.contains(tab.id))
                .toList(growable: false)
            : allTabs;

    debugPrint(
      '[Home] build currentIndex=$_currentIndex tabs=${tabs.map((t) => t.id).toList()}',
    );

    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }
    if (_lastTabId != null && tabs.every((tab) => tab.id != _lastTabId)) {
      // Wenn der bisher aktive Tab entfernt wurde (z.B. Workout-Tab),
      // immer auf Profil zurückfallen.
      final profileIndex = tabs.indexWhere(
        (tab) => tab.id == _HomeTabId.profile,
      );
      _currentIndex = profileIndex >= 0 ? profileIndex : 0;
    }
    final currentTab = tabs[_currentIndex];
    final currentLabel = currentTab.item.label ?? '';
    _lastTabId = currentTab.id;

    return Scaffold(
      appBar: currentTab.id == _HomeTabId.workout
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              centerTitle: true,
              leadingWidth: kToolbarHeight + 8,
              leading: const SizedBox(width: kToolbarHeight + 8),
              title: _buildAppBarTitle(context, currentLabel),
              actions: isGuest
                  ? [
                      TextButton(
                        onPressed: () => _exitDemo(context),
                        child: Text(
                          loc.gymDemoExitCta,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ]
                  : [
                      const NfcScanButton(),
                      const SizedBox(width: 8),
                    ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [for (final t in tabs) t.page],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          // Beim Tab-Wechsel immer Overlay-Keypad schließen, damit es nicht liegen bleibt.
          ref.read(overlayNumericKeypadControllerProvider).close();
          setState(() => _currentIndex = i);
        },
        items: [for (final t in tabs) t.item],
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context, String currentLabel) {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final gymName = ref.watch(gymProvider.select((g) => g.gym?.name));

    String titleText;
    switch (_currentIndex) {
      case 0:
        titleText = (gymName != null && gymName.trim().isNotEmpty) ? gymName : loc.gymTitle;
        break;
      case 1:
        titleText = auth.userName ?? auth.userEmail ?? loc.profileTitle;
        break;
      default:
        titleText = currentLabel.isNotEmpty ? currentLabel : loc.appTitle;
        break;
    }

    return TimerAppBarTitle(
      title: BrandGradientText(
        titleText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
        maxLines: 1,
      ),
    );
  }

  Future<void> _exitDemo(BuildContext context) async {
    final auth = ref.read(authControllerProvider);
    final gymId = auth.gymCode;
    await auth.exitDemoMode();
    if (!context.mounted) return;
    if (gymId != null && gymId.isNotEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.gymAccess,
        (route) => false,
        arguments: gymId,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.gymEntry,
        (route) => false,
      );
    }
  }
}

enum _HomeTabId {
  gym,
  profile,
  nutrition,
  workout,
  report,
  admin,
  rank,
  deals,
  plan,
  coaching,
}

class _TabInfo {
  final _HomeTabId id;
  final Widget page;
  final BottomNavigationBarItem item;
  const _TabInfo({required this.id, required this.page, required this.item});
}

/// Fallback-Screen für den Workout-Tab, wenn der Timer bereits läuft,
/// aber noch keine Session existiert und kein geeignetes Gerät gefunden wurde.
class _EmptyWorkoutScreen extends StatelessWidget {
  const _EmptyWorkoutScreen();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Der Trainingstag ist aktiv, aber es wurde noch kein Studio oder Gerät ausgewählt.\n\n'
            'Wähle zuerst ein Gym aus, um dein Workout zu starten.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.selectGym);
            },
            child: const Text('Gym auswählen'),
          ),
        ),
      ),
    );
  }
}
