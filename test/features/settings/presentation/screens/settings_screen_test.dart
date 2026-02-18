import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/observability/offline_flow_observability_service.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/database_provider.dart';
import 'package:tapem/core/providers/offline_flow_observability_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/sync/sync_service.dart';
import 'package:tapem/core/theme/brand_theme_preset.dart';
import 'package:tapem/features/settings/presentation/screens/settings_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../../../helpers/fake_settings_provider.dart';

class _MockThemePreferenceProvider extends Mock
    with ChangeNotifier
    implements ThemePreferenceProvider {}

class _MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

class _MockSyncService extends Mock implements SyncService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(BrandThemeId.mintTurquoise);
  });

  testWidgets('renders key settings tiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appProvider = app.AppProvider(preferences: prefs);
    final themePref = _MockThemePreferenceProvider();
    final authProvider = _MockAuthProvider();
    final syncService = _MockSyncService();
    final syncStatus = ValueNotifier<SyncQueueStatus>(
      const SyncQueueStatus.initial(),
    );
    final settingsProvFake = FakeSettingsProvider(
      creatineEnabled: true,
      gender: 'm',
      bodyWeightKg: 82.5,
    );

    when(() => themePref.override).thenReturn(null);
    when(
      () => themePref.manualDefaultForGym(any()),
    ).thenReturn(BrandThemeId.mintTurquoise);
    when(
      () => themePref.availableForGym(any()),
    ).thenReturn(List.of(BrandThemeId.values));
    when(() => themePref.setTheme(any())).thenAnswer((_) async {});

    when(() => authProvider.userName).thenReturn('Tester');
    when(() => authProvider.publicProfile).thenReturn(true);
    when(() => authProvider.showInLeaderboard).thenReturn(true);
    when(() => authProvider.gymCode).thenReturn('gym-1');
    when(() => syncService.statusListenable).thenReturn(syncStatus);
    when(() => syncService.status).thenReturn(syncStatus.value);
    when(() => syncService.syncPendingJobs()).thenAnswer((_) async {});
    when(() => syncService.replayDeadLetterJobs()).thenAnswer((_) async => 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          app.appProvider.overrideWith((ref) => appProvider),
          themePreferenceProvider.overrideWith((ref) => themePref),
          authControllerProvider.overrideWith((ref) => authProvider),
          settingsProvider.overrideWith((ref) => settingsProvFake),
          syncServiceProvider.overrideWith((ref) => syncService),
          offlineFlowObservabilityProvider.overrideWith(
            (ref) => OfflineFlowObservabilityService.instance,
          ),
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
  });
}
