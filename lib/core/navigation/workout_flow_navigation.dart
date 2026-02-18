import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tapem/app_router.dart';

const _defaultNavRetryDelay = Duration(milliseconds: 120);
const _defaultNavMaxAttempts = 8;

void _workoutFlowNavLog(String message) {
  debugPrint('🏁 [WorkoutFlowNav] $message');
}

Future<void> navigateToHomeProfile({
  required GlobalKey<NavigatorState> navigatorKey,
  required String source,
  bool force = true,
  Duration retryDelay = _defaultNavRetryDelay,
  int maxAttempts = _defaultNavMaxAttempts,
}) async {
  final cappedAttempts = maxAttempts < 1 ? 1 : maxAttempts;
  for (var attempt = 1; attempt <= cappedAttempts; attempt++) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.mounted) {
      final currentRoute = ModalRoute.of(nav.context)?.settings.name;
      if (!force && currentRoute == AppRouter.home) {
        _workoutFlowNavLog(
          'navigate_profile_skipped source=$source reason=already_home',
        );
        return;
      }
      _workoutFlowNavLog(
        'navigate_profile_dispatched source=$source attempt=$attempt currentRoute=${currentRoute ?? '-'}',
      );
      nav.pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
        arguments: 1,
      );
      return;
    }
    if (attempt < cappedAttempts) {
      await Future<void>.delayed(retryDelay);
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = navigatorKey.currentState;
    if (nav == null || !nav.mounted) {
      _workoutFlowNavLog(
        'navigate_profile_failed source=$source reason=navigator_unavailable',
      );
      return;
    }
    final currentRoute = ModalRoute.of(nav.context)?.settings.name;
    _workoutFlowNavLog(
      'navigate_profile_dispatched source=$source attempt=post_frame currentRoute=${currentRoute ?? '-'}',
    );
    nav.pushNamedAndRemoveUntil(AppRouter.home, (route) => false, arguments: 1);
  });
}
