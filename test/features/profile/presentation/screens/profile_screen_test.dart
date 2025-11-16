import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/features/friends/providers/friend_alerts_provider.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/features/settings/presentation/screens/settings_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/main.dart';

import '../../../../helpers/fake_settings_provider.dart';

class _MockProfileProvider extends Mock implements ProfileProvider {}

class _MockAuthProvider extends Mock implements AuthProvider {}

class _MockFriendAlertsProvider extends Mock implements FriendAlertsProvider {}

class _MockXpProvider extends Mock implements XpProvider {}

class _MockGymProvider extends Mock implements GymProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockProfileProvider profileProvider;
  late _MockAuthProvider authProvider;
  late _MockFriendAlertsProvider friendAlertsProvider;
  late _MockXpProvider xpProvider;
  late _MockGymProvider gymProvider;
  late SettingsProvider settingsProvider;

  setUp(() {
    profileProvider = _MockProfileProvider();
    authProvider = _MockAuthProvider();
    friendAlertsProvider = _MockFriendAlertsProvider();
    xpProvider = _MockXpProvider();
    gymProvider = _MockGymProvider();
    settingsProvider = FakeSettingsProvider();

    when(() => profileProvider.isLoading).thenReturn(false);
    when(() => profileProvider.error).thenReturn(null);
    when(() => profileProvider.trainingDates).thenReturn(const []);
    when(() => profileProvider.loadTrainingDates(any())).thenAnswer((_) async {});

    when(() => authProvider.userId).thenReturn('user-1');
    when(() => authProvider.gymCode).thenReturn('gym-1');
    when(() => authProvider.avatarKey).thenReturn('default');
    when(() => authProvider.userName).thenReturn('Tester');
    when(() => authProvider.setAvatarKey(any())).thenAnswer((_) async {});

    when(() => friendAlertsProvider.showBadge).thenReturn(false);
    when(() => friendAlertsProvider.listen(any())).thenReturn(null);

    when(() => xpProvider.dailyLevel).thenReturn(1);
    when(() => xpProvider.dailyLevelXp).thenReturn(50);
    when(() => xpProvider.statsDailyXp).thenReturn(200);
    when(() => xpProvider.watchStatsDailyXp(any(), any())).thenReturn(null);

    when(() => gymProvider.currentGymId).thenReturn('gym-1');
  });

  Route<dynamic> _testRouteFactory(RouteSettings settings) {
    if (settings.name == Navigator.defaultRouteName) {
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    }
    return AppRouter.onGenerateRoute(settings);
  }

  testWidgets('tapping settings action opens SettingsScreen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ProfileProvider>.value(value: profileProvider),
          Provider<AuthProvider>.value(value: authProvider),
          Provider<FriendAlertsProvider>.value(value: friendAlertsProvider),
          Provider<XpProvider>.value(value: xpProvider),
          Provider<SettingsProvider>.value(value: settingsProvider),
          Provider<GymProvider>.value(value: gymProvider),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: _testRouteFactory,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
