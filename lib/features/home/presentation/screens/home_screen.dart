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
import 'package:tapem/features/home/presentation/widgets/overlay_feature_navigators.dart';
import 'package:tapem/features/home/domain/home_tab_policy.dart';
import 'package:tapem/features/home/presentation/widgets/owner_tab_navigator.dart';
import 'package:tapem/features/training_plan/presentation/widgets/training_plan_tab_navigator.dart';
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
  final GlobalKey<NavigatorState> _nutritionNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _planNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _ownerNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _nutritionOverlayNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _planOverlayNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _progressOverlayNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _discoverOverlayNavigatorKey =
      GlobalKey<NavigatorState>();
  _HomeOverlayFeature? _overlayFeature;
  DiscoverInitialPage _discoverInitialPage = DiscoverInitialPage.stats;

  void _switchToProfileTab() {
    if (!mounted) return;
    setState(() {
      _overlayFeature = null;
      _currentIndex = 1;
    });
  }

  List<_TabInfo> _buildTabs(BuildContext context) {
    final gymProv = ref.watch(gymProvider);
    final gymId = gymProv.currentGymId;
    final devices = gymProv.devices.where((d) => !d.isMulti).toList();
    final deviceId = devices.isNotEmpty ? devices.first.uid : '';
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final wsds.WorkoutSessionDurationService timerService = ref.watch(
      workoutSessionDurationServiceProvider,
    );
    final WorkoutDayController workoutController = ref.read(
      workoutDayControllerProvider,
    );

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
        item: _HomeTabBarItem(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          label: loc.gymTitle,
          barLabel: 'Gym',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.profile,
        page: ProfileScreen(
          key: const PageStorageKey('Profile'),
          onOpenProgress: () =>
              _openOverlayFeature(_HomeOverlayFeature.progress),
          onOpenNutrition: () =>
              _openOverlayFeature(_HomeOverlayFeature.nutrition),
          onOpenPlan: () => _openOverlayFeature(_HomeOverlayFeature.plan),
          onOpenDiscoverStats: () => _openOverlayFeature(
            _HomeOverlayFeature.discover,
            discoverInitialPage: DiscoverInitialPage.stats,
          ),
          onOpenDiscoverCommunity: () => _openOverlayFeature(
            _HomeOverlayFeature.discover,
            discoverInitialPage: DiscoverInitialPage.community,
          ),
          onOpenDiscoverSurveys: () => _openOverlayFeature(
            _HomeOverlayFeature.discover,
            discoverInitialPage: DiscoverInitialPage.surveys,
          ),
        ),
        item: _HomeTabBarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: loc.profileTitle,
          barLabel: 'Profil',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.nutrition,
        // Eigenes Navigator-Stack für Ernährung, damit BottomTab sichtbar bleibt
        page: NutritionTabNavigator(
          key: const PageStorageKey('NutritionTab'),
          navigatorKey: _nutritionNavigatorKey,
          onExitToProfile: _switchToProfileTab,
        ),
        item: _HomeTabBarItem(
          icon: Icons.restaurant_outlined,
          activeIcon: Icons.restaurant,
          label: loc.homeTabNutrition,
          barLabel: 'Food',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.report,
        page: const ReportScreen(key: PageStorageKey('Report')),
        item: _HomeTabBarItem(
          icon: Icons.insert_chart_outlined,
          activeIcon: Icons.insert_chart,
          label: loc.reportTitle,
          barLabel: 'Report',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.admin,
        page: const AdminDashboardScreen(key: PageStorageKey('Admin')),
        item: _HomeTabBarItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: loc.homeTabAdmin,
          barLabel: 'Admin',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.rank,
        page: RankScreen(
          key: const PageStorageKey('Rank'),
          gymId: gymId,
          deviceId: deviceId,
          isPrimaryTab: true,
        ),
        item: _HomeTabBarItem(
          icon: Icons.leaderboard_outlined,
          activeIcon: Icons.leaderboard,
          label: loc.homeTabRank,
          barLabel: 'Rank',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.deals,
        page: const DealsScreen(key: PageStorageKey('Deals')),
        item: _HomeTabBarItem(
          icon: Icons.local_offer_outlined,
          activeIcon: Icons.local_offer,
          label: loc.homeTabDeals,
          barLabel: 'Deals',
        ),
      ),
      _TabInfo(
        id: _HomeTabId.plan,
        page: TrainingPlanTabNavigator(
          key: const PageStorageKey('PlaeneTab'),
          navigatorKey: _planNavigatorKey,
          onExitToProfile: _switchToProfileTab,
        ),
        item: _HomeTabBarItem(
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note,
          label: loc.homeTabPlans,
          barLabel: 'Plan',
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
        item: _HomeTabBarItem(
          icon: Icons.play_circle_outline,
          activeIcon: Icons.play_circle,
          label: 'Workout',
          barLabel: 'Train',
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
          page: const CoachingHomeScreen(key: PageStorageKey('Coaching')),
          item: _HomeTabBarItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Coaching',
            barLabel: 'Coach',
          ),
        ),
      );
    }

    if (auth.isGymOwner) {
      tabs.add(
        _TabInfo(
          id: _HomeTabId.owner,
          page: OwnerTabNavigator(
            key: const PageStorageKey('Owner'),
            navigatorKey: _ownerNavigatorKey,
          ),
          item: const _HomeTabBarItem(
            icon: Icons.workspace_premium_outlined,
            activeIcon: Icons.workspace_premium,
            label: 'Owner',
            barLabel: 'Owner',
          ),
        ),
      );
    }

    return tabs;
  }

  void _openOverlayFeature(
    _HomeOverlayFeature feature, {
    DiscoverInitialPage discoverInitialPage = DiscoverInitialPage.stats,
  }) {
    ref.read(overlayNumericKeypadControllerProvider).close();
    setState(() {
      _overlayFeature = feature;
      _discoverInitialPage = discoverInitialPage;
    });
  }

  Widget? _buildOverlayBody({
    required String gymId,
    required String userId,
    required VoidCallback onExitToProfile,
  }) {
    switch (_overlayFeature) {
      case _HomeOverlayFeature.progress:
        return ProgressTabNavigator(
          key: const PageStorageKey('ProgressOverlay'),
          navigatorKey: _progressOverlayNavigatorKey,
          onExitToProfile: onExitToProfile,
        );
      case _HomeOverlayFeature.nutrition:
        return NutritionTabNavigator(
          key: const PageStorageKey('NutritionOverlay'),
          navigatorKey: _nutritionOverlayNavigatorKey,
          onExitToProfile: onExitToProfile,
        );
      case _HomeOverlayFeature.plan:
        return TrainingPlanTabNavigator(
          key: const PageStorageKey('PlanOverlay'),
          navigatorKey: _planOverlayNavigatorKey,
          onExitToProfile: onExitToProfile,
        );
      case _HomeOverlayFeature.discover:
        return DiscoverTabNavigator(
          key: ValueKey<String>('DiscoverOverlay-${_discoverInitialPage.name}'),
          navigatorKey: _discoverOverlayNavigatorKey,
          gymId: gymId,
          userId: userId,
          initialPage: _discoverInitialPage,
          onExitToProfile: onExitToProfile,
        );
      case null:
        return null;
    }
  }

  NavigatorState? _activeOverlayNavigator() {
    switch (_overlayFeature) {
      case _HomeOverlayFeature.progress:
        return _progressOverlayNavigatorKey.currentState;
      case _HomeOverlayFeature.nutrition:
        return _nutritionOverlayNavigatorKey.currentState;
      case _HomeOverlayFeature.plan:
        return _planOverlayNavigatorKey.currentState;
      case _HomeOverlayFeature.discover:
        return _discoverOverlayNavigatorKey.currentState;
      case null:
        return null;
    }
  }

  Future<bool> _handleWillPop() async {
    if (_overlayFeature == null) {
      final activeTabId = _lastTabId;
      final tabNavigator = _tabNavigatorFor(activeTabId);
      if (tabNavigator != null) {
        final handled = await tabNavigator.maybePop();
        if (handled) {
          return false;
        }
      }
      return true;
    }
    final overlayNavigator = _activeOverlayNavigator();
    if (overlayNavigator != null) {
      final handled = await overlayNavigator.maybePop();
      if (handled) {
        return false;
      }
    }
    _switchToProfileTab();
    return false;
  }

  NavigatorState? _tabNavigatorFor(_HomeTabId? tabId) {
    switch (tabId) {
      case _HomeTabId.nutrition:
        return _nutritionNavigatorKey.currentState;
      case _HomeTabId.plan:
        return _planNavigatorKey.currentState;
      case _HomeTabId.owner:
        return _ownerNavigatorKey.currentState;
      case _HomeTabId.gym:
      case _HomeTabId.profile:
      case _HomeTabId.workout:
      case _HomeTabId.report:
      case _HomeTabId.admin:
      case _HomeTabId.rank:
      case _HomeTabId.deals:
      case _HomeTabId.coaching:
      case null:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    debugPrint('[Home] initState initialIndex=${widget.initialIndex}');
    // Nach Login Gym laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = ref.read(authControllerProvider);
      debugPrint(
        '[Tabs] role=${authProv.role}, isAdmin=${authProv.isAdmin}, restricted=${FF.limitTabsForMembers}',
      );
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
    final accessTier = auth.accessTier;
    final allTabs = _buildTabs(context);
    final allowedSlots = visibleHomeTabSlotsForAccessTier(accessTier);
    final tabs = allTabs
        .where((tab) => allowedSlots.contains(tab.id.slot))
        .toList(growable: false);

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
    _lastTabId = currentTab.id;
    final overlayBody = _buildOverlayBody(
      gymId: auth.gymCode ?? '',
      userId: auth.userId ?? '',
      onExitToProfile: _switchToProfileTab,
    );

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        extendBody: false,
        appBar:
            (overlayBody != null ||
                currentTab.id == _HomeTabId.workout ||
                currentTab.id == _HomeTabId.owner)
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                centerTitle: true,
                leadingWidth: kToolbarHeight + 8,
                leading: const SizedBox(width: kToolbarHeight + 8),
                title: _buildAppBarTitle(context, currentTab),
                actions: auth.isGuest
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
                    : [const NfcScanButton(), const SizedBox(width: 8)],
              ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: [for (final t in tabs) t.page],
              ),
            ),
            if (overlayBody != null) Positioned.fill(child: overlayBody),
          ],
        ),
        bottomNavigationBar: _HomeBottomBar(
          currentIndex: _currentIndex,
          tabs: tabs,
          onTap: (index) {
            // Beim Tab-Wechsel immer Overlay-Keypad schließen, damit es nicht liegen bleibt.
            ref.read(overlayNumericKeypadControllerProvider).close();
            if (_overlayFeature != null) {
              setState(() {
                _overlayFeature = null;
                _currentIndex = index;
              });
              return;
            }
            if (index == _currentIndex) {
              if (tabs[index].id == _HomeTabId.nutrition) {
                final nav = _nutritionNavigatorKey.currentState;
                nav?.popUntil((route) => route.isFirst);
              } else if (tabs[index].id == _HomeTabId.plan) {
                final nav = _planNavigatorKey.currentState;
                nav?.popUntil((route) => route.isFirst);
              } else if (tabs[index].id == _HomeTabId.owner) {
                final nav = _ownerNavigatorKey.currentState;
                nav?.popUntil((route) => route.isFirst);
              }
              return;
            }
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context, _TabInfo currentTab) {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);
    final gymName = ref.watch(gymProvider.select((g) => g.gym?.name));

    String titleText;
    switch (currentTab.id) {
      case _HomeTabId.gym:
        titleText = (gymName != null && gymName.trim().isNotEmpty)
            ? gymName
            : loc.gymTitle;
        break;
      case _HomeTabId.profile:
        titleText = auth.userName ?? auth.userEmail ?? loc.profileTitle;
        break;
      default:
        titleText = currentTab.item.label.isNotEmpty
            ? currentTab.item.label
            : loc.appTitle;
        break;
    }

    return TimerAppBarTitle(
      title: BrandGradientText(
        titleText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
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
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.gymEntry, (route) => false);
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
  owner,
  deals,
  plan,
  coaching,
}

extension on _HomeTabId {
  HomeTabSlot get slot {
    return switch (this) {
      _HomeTabId.gym => HomeTabSlot.gym,
      _HomeTabId.profile => HomeTabSlot.profile,
      _HomeTabId.nutrition => HomeTabSlot.nutrition,
      _HomeTabId.workout => HomeTabSlot.workout,
      _HomeTabId.report => HomeTabSlot.report,
      _HomeTabId.admin => HomeTabSlot.admin,
      _HomeTabId.rank => HomeTabSlot.rank,
      _HomeTabId.owner => HomeTabSlot.owner,
      _HomeTabId.deals => HomeTabSlot.deals,
      _HomeTabId.plan => HomeTabSlot.plan,
      _HomeTabId.coaching => HomeTabSlot.coaching,
    };
  }
}

enum _HomeOverlayFeature { progress, nutrition, plan, discover }

class _TabInfo {
  final _HomeTabId id;
  final Widget page;
  final _HomeTabBarItem item;
  const _TabInfo({required this.id, required this.page, required this.item});
}

class _HomeTabBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String barLabel;

  const _HomeTabBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.barLabel,
  });
}

class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_TabInfo> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = Color.alphaBlend(
      Colors.white.withOpacity(0.08),
      scheme.secondary,
    );
    final barBackground = theme.scaffoldBackgroundColor;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tabCount = tabs.length;
    final compactMode = tabCount >= 7 || screenWidth < 390;
    final showSelectedLabel = tabCount <= 4;
    final horizontalInset = tabCount <= 4 ? 16.0 : (compactMode ? 8.0 : 10.0);
    final minTapHeight = compactMode ? 54.0 : 58.0;

    return ColoredBox(
      color: barBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalInset, 6, horizontalInset, 6),
          child: Row(
            children: [
              for (var index = 0; index < tabs.length; index++)
                Expanded(
                  child: _HomeBottomBarButton(
                    item: tabs[index].item,
                    isSelected: index == currentIndex,
                    onTap: () => onTap(index),
                    showSelectedLabel: showSelectedLabel,
                    minTapHeight: minTapHeight,
                    selectedColor: activeColor.withOpacity(0.34),
                    selectedBorderColor: activeColor.withOpacity(0.44),
                    selectedIconColor: Colors.white.withOpacity(0.92),
                    unselectedIconColor: scheme.onSurface.withOpacity(0.62),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBottomBarButton extends StatelessWidget {
  const _HomeBottomBarButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showSelectedLabel,
    required this.minTapHeight,
    required this.selectedColor,
    required this.selectedBorderColor,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.labelStyle,
  });

  final _HomeTabBarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showSelectedLabel;
  final double minTapHeight;
  final Color selectedColor;
  final Color selectedBorderColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          child: SizedBox(
            height: minTapHeight,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canShowLabel =
                    isSelected &&
                    showSelectedLabel &&
                    constraints.maxWidth >= 108;

                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 42),
                    padding: EdgeInsets.symmetric(
                      horizontal: canShowLabel ? 14 : 10,
                      vertical: 9,
                    ),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selectedBorderColor,
                              width: 1,
                            ),
                          )
                        : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: canShowLabel
                          ? ConstrainedBox(
                              key: ValueKey<String>(
                                'selected-label-${item.barLabel}',
                              ),
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth - 16,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.activeIcon,
                                    size: 23,
                                    color: selectedIconColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      item.barLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: labelStyle?.copyWith(
                                        color: selectedIconColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Icon(
                              key: ValueKey<bool>(isSelected),
                              isSelected ? item.activeIcon : item.icon,
                              size: 26,
                              color: isSelected
                                  ? selectedIconColor
                                  : unselectedIconColor,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
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
      appBar: AppBar(title: Text(loc.appTitle), centerTitle: true),
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
