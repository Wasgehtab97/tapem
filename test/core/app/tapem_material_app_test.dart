import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/app/tapem_app.dart';
import 'package:tapem/core/providers/app_provider.dart';
import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

void main() {
  group('TapemMaterialApp', () {
    testWidgets('rebuilds theme on simulated gym switch', (tester) async {
      final themeLoader = _TestThemeLoader();
      final app = AppProvider();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeLoaderProvider.overrideWith((ref) => themeLoader),
            appProvider.overrideWith((ref) => app),
          ],
          child: const TapemMaterialApp(),
        ),
      );

      MaterialApp materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, Brightness.light);

      themeLoader.updateTheme(ThemeData(brightness: Brightness.dark));
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, Brightness.dark);
    });

    testWidgets('updates locale when the active auth profile changes',
        (tester) async {
      final themeLoader = _TestThemeLoader();
      final app = AppProvider();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeLoaderProvider.overrideWith((ref) => themeLoader),
            appProvider.overrideWith((ref) => app),
          ],
          child: const TapemMaterialApp(),
        ),
      );

      MaterialApp materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale, isNull);

      app.setLocale(const Locale('de'));
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale?.languageCode, 'de');
    });
  });
}

class _TestThemeLoader extends ThemeLoader {
  ThemeData _theme = ThemeData.light();

  @override
  ThemeData get theme => _theme;

  void updateTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }
}
