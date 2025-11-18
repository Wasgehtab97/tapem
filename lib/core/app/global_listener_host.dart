// lib/core/app/global_listener_host.dart

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';

import '../../bootstrap/navigation.dart';
import '../../features/auth/presentation/widgets/dynamic_link_listener.dart';
import '../../features/nfc/widgets/global_nfc_listener.dart';
import '../../features/story_session/presentation/widgets/story_session_highlights_listener.dart';

class GlobalListenerHost extends StatelessWidget {
  const GlobalListenerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget app = child;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      app = GlobalNfcListener(child: app);
    }
    app = DynamicLinkListener(child: app);
    app = StorySessionHighlightsListener(
      navigatorKey: navigatorKey,
      child: app,
    );
    return app;
  }
}
