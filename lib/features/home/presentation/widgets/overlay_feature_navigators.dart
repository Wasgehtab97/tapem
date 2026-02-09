import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/community/presentation/screens/community_screen.dart';
import 'package:tapem/features/profile/presentation/screens/powerlifting_screen.dart';
import 'package:tapem/features/profile/presentation/screens/profile_stats_screen.dart';
import 'package:tapem/features/progress/presentation/screens/progress_screen.dart';
import 'package:tapem/features/rest_stats/presentation/screens/rest_stats_screen.dart';
import 'package:tapem/features/survey/presentation/screens/survey_vote_screen.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _OverlayCloseObserver extends NavigatorObserver {
  _OverlayCloseObserver(this.controller);

  final OverlayNumericKeypadController controller;

  void _close() {
    controller.close();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _close();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _close();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _close();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _close();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class ProgressTabNavigator extends ConsumerWidget {
  const ProgressTabNavigator({
    super.key,
    this.navigatorKey,
    this.onExitToProfile,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final VoidCallback? onExitToProfile;

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.progress:
        return MaterialPageRoute(
          builder: (_) => ProgressScreen(onExitToProfile: onExitToProfile),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => ProgressScreen(onExitToProfile: onExitToProfile),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keypad = ref.watch(overlayNumericKeypadControllerProvider);
    return Navigator(
      key: navigatorKey,
      onGenerateInitialRoutes: (_, __) => <Route<dynamic>>[
        _onGenerateRoute(const RouteSettings(name: AppRouter.progress)),
      ],
      onGenerateRoute: _onGenerateRoute,
      observers: [_OverlayCloseObserver(keypad)],
    );
  }
}

enum DiscoverInitialPage { stats, community, surveys }

class DiscoverTabNavigator extends ConsumerWidget {
  const DiscoverTabNavigator({
    super.key,
    this.navigatorKey,
    required this.gymId,
    required this.userId,
    this.initialPage = DiscoverInitialPage.stats,
    this.onExitToProfile,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final String gymId;
  final String userId;
  final DiscoverInitialPage initialPage;
  final VoidCallback? onExitToProfile;

  static const String _statsRoute = '/discover/stats';
  static const String _communityRoute = '/discover/community';
  static const String _surveysRoute = '/discover/surveys';

  String get _initialRoute {
    switch (initialPage) {
      case DiscoverInitialPage.stats:
        return _statsRoute;
      case DiscoverInitialPage.community:
        return _communityRoute;
      case DiscoverInitialPage.surveys:
        return _surveysRoute;
    }
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case _statsRoute:
        return MaterialPageRoute(
          builder: (_) => ProfileStatsScreen(onExitToProfile: onExitToProfile),
        );
      case _communityRoute:
        return MaterialPageRoute(
          builder: (_) => CommunityScreen(onExitToProfile: onExitToProfile),
        );
      case _surveysRoute:
        return MaterialPageRoute(
          builder: (_) => SurveyVoteScreen(
            gymId: gymId,
            userId: userId,
            onExitToProfile: onExitToProfile,
          ),
        );
      case AppRouter.restStats:
        return MaterialPageRoute(builder: (_) => const RestStatsScreen());
      case AppRouter.powerlifting:
        return MaterialPageRoute(builder: (_) => const PowerliftingScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => ProfileStatsScreen(onExitToProfile: onExitToProfile),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keypad = ref.watch(overlayNumericKeypadControllerProvider);
    return Navigator(
      key: navigatorKey,
      onGenerateInitialRoutes: (_, __) => <Route<dynamic>>[
        _onGenerateRoute(RouteSettings(name: _initialRoute)),
      ],
      onGenerateRoute: _onGenerateRoute,
      observers: [_OverlayCloseObserver(keypad)],
    );
  }
}
