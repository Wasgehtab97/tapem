import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/widgets/gym_context_guard.dart';
import 'package:tapem/features/history/presentation/screens/history_screen.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_detail_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_exercise_picker_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_overview_screen.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _PlanOverlayCloseObserver extends NavigatorObserver {
  _PlanOverlayCloseObserver(this.controller);

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

/// Separater Navigator-Stack für Trainingspläne, damit die BottomTabbar
/// auch in Detail-/Picker-Flows sichtbar bleibt.
class TrainingPlanTabNavigator extends ConsumerWidget {
  const TrainingPlanTabNavigator({
    super.key,
    this.navigatorKey,
    this.onExitToProfile,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final VoidCallback? onExitToProfile;

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.planOverview:
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(
            child: PlanOverviewScreen(onExitToProfile: onExitToProfile),
          ),
        );
      case AppRouter.trainingPlanDetail:
        final plan = settings.arguments as TrainingPlan?;
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(child: PlanDetailScreen(plan: plan)),
        );
      case AppRouter.trainingPlanPicker:
        return MaterialPageRoute(
          builder: (_) =>
              const GymContextGuard(child: PlanExercisePickerScreen()),
        );
      case AppRouter.history:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(
            deviceId: args['deviceId'] as String,
            deviceName: args['deviceName'] as String,
            deviceDescription: args['deviceDescription'] as String?,
            isMulti: args['isMulti'] as bool? ?? false,
            exerciseId: args['exerciseId'] as String?,
            exerciseName: args['exerciseName'] as String?,
            ownerUserId: args['userId'] as String?,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(
            child: PlanOverviewScreen(onExitToProfile: onExitToProfile),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keypad = ref.watch(overlayNumericKeypadControllerProvider);
    return Navigator(
      key: navigatorKey,
      onGenerateInitialRoutes: (_, __) => <Route<dynamic>>[
        _onGenerateRoute(const RouteSettings(name: AppRouter.planOverview)),
      ],
      onGenerateRoute: _onGenerateRoute,
      observers: [_PlanOverlayCloseObserver(keypad)],
    );
  }
}
