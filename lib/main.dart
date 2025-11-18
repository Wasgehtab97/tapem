// lib/main.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap.dart';
import 'core/app/tapem_app.dart';

Future<void> main() async {
  final bootstrapResult = await bootstrapApp();
  runApp(
    ProviderScope(
      overrides: bootstrapResult.toOverrides(),
      child: const TapemApp(),
    ),
  );
}
