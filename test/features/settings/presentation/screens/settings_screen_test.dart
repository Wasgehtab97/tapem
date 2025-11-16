import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/app_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/theme/brand_theme_preset.dart';
import 'package:tapem/features/settings/presentation/screens/settings_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../../../helpers/fake_settings_provider.dart';

class _MockThemePreferenceProvider extends Mock implements ThemePreferenceProvider {}

class _MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(BrandThemeId.mintTurquoise);
  });

  testWidgets('renders key settings tiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appProvider = AppProvider(preferences: prefs);
    final themePref = _MockThemePreferenceProvider();
    final authProvider = _MockAuthProvider();
    final settingsProvider = FakeSettingsProvider(
      creatineEnabled: true,
      gender: 'm',
      bodyWeightKg: 82.5,
    );

    when(() => themePref.override).thenReturn(null);
    when(() => themePref.manualDefaultForGym(any())).thenReturn(BrandThemeId.mintTurquoise);
    when(() => themePref.availableForGym(any())).thenReturn(List.of(BrandThemeId.values));
    when(() => themePref.setTheme(any())).thenAnswer((_) async {});

    when(() => authProvider.userName).thenReturn('Tester');
    when(() => authProvider.publicProfile).thenReturn(true);
    when(() => authProvider.showInLeaderboard).thenReturn(true);
    when(() => authProvider.gymCode).thenReturn('gym-1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: appProvider),
          Provider<ThemePreferenceProvider>.value(value: themePref),
          Provider<AuthProvider>.value(value: authProvider),
          Provider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Body metrics'), findsOneWidget);
    expect(find.text('Creatine tracker'), findsOneWidget);
    expect(find.text('Public profile'), findsOneWidget);
    expect(find.text('Change username'), findsOneWidget);
    expect(find.text('Imprint'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
  });
}
