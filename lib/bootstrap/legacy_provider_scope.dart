// lib/bootstrap/legacy_provider_scope.dart
//
// Nach der vollständigen Migration der UI auf Riverpod wird der frühere
// Legacy‑Adapter (`provider.MultiProvider` mit ChangeNotifiers) nicht mehr
// benötigt. Die Klasse bleibt als dünner Wrapper bestehen, damit
// bestehender Code (z.B. `TapemApp`, Tests, Dokumentation) weiterhin
// kompiliert, ohne noch eine echte Provider‑Hierarchie aufzubauen.

import 'package:flutter/widgets.dart';

class LegacyProviderScope extends StatelessWidget {
  const LegacyProviderScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
