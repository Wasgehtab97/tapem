import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/auth/presentation/widgets/dynamic_link_listener.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import '../../../helpers/recording_navigator_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp({
    required DynamicLinkListener listener,
    RecordingNavigatorObserver? observer,
  }) {
    return MaterialApp(
      home: listener,
      routes: <String, WidgetBuilder>{
        AppRouter.resetPassword: (_) => const Scaffold(body: Text('reset')),
      },
      navigatorObservers:
          observer != null ? <NavigatorObserver>[observer] : const [],
    );
  }

  group('DynamicLinkListener', () {
    testWidgets('navigates when initial link requests password reset',
        (WidgetTester tester) async {
      final observer = RecordingNavigatorObserver();
      final listener = DynamicLinkListener(
        child: const Scaffold(),
        getInitialLink: () async => PendingDynamicLinkData(
          link: Uri.parse(
            'https://example.com/path?mode=resetPassword&oobCode=abc',
          ),
        ),
        onLinkStream: const Stream<PendingDynamicLinkData>.empty(),
      );

      await tester.pumpWidget(buildApp(listener: listener, observer: observer));
      await tester.pump();

      expect(
        observer.pushedRoutes
            .map((Route<dynamic> route) => route.settings.name)
            .whereType<String>()
            .contains(AppRouter.resetPassword),
        isTrue,
      );
    });

    testWidgets('ignores non reset links', (WidgetTester tester) async {
      final observer = RecordingNavigatorObserver();
      final listener = DynamicLinkListener(
        child: const Scaffold(),
        getInitialLink: () async => PendingDynamicLinkData(
          link: Uri.parse('https://example.com/path?mode=signIn'),
        ),
        onLinkStream: const Stream<PendingDynamicLinkData>.empty(),
      );

      await tester.pumpWidget(buildApp(listener: listener, observer: observer));
      await tester.pump();

      expect(
        observer.pushedRoutes
            .map((Route<dynamic> route) => route.settings.name)
            .whereType<String>()
            .contains(AppRouter.resetPassword),
        isFalse,
      );
    });

    testWidgets('responds to stream events', (WidgetTester tester) async {
      final controller = StreamController<PendingDynamicLinkData>();
      final observer = RecordingNavigatorObserver();
      final listener = DynamicLinkListener(
        child: const Scaffold(),
        getInitialLink: () async => null,
        onLinkStream: controller.stream,
      );

      await tester.pumpWidget(buildApp(listener: listener, observer: observer));
      await tester.pump();

      controller.add(
        PendingDynamicLinkData(
          link: Uri.parse(
            'https://example.com/path?mode=resetPassword&oobCode=xyz',
          ),
        ),
      );
      await tester.pump();

      expect(
        observer.pushedRoutes
            .map((Route<dynamic> route) => route.settings.name)
            .whereType<String>()
            .contains(AppRouter.resetPassword),
        isTrue,
      );

      await controller.close();
    });
  });
}
