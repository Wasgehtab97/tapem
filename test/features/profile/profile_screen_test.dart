import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class MockAuthProvider extends Mock with ChangeNotifier implements AuthProvider {}
class MockProfileProvider extends Mock with ChangeNotifier implements ProfileProvider {}
class MockSettingsProvider extends Mock with ChangeNotifier implements SettingsProvider {}
class MockFriendsProvider extends Mock with ChangeNotifier implements FriendsProvider {}
class MockGymProvider extends Mock with ChangeNotifier implements GymProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue<String>('');
  });

  Widget buildScreen({
    required AuthProvider auth,
    required ProfileProvider profile,
    required SettingsProvider settings,
    required FriendsProvider friends,
    required GymProvider gym,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<ProfileProvider>.value(value: profile),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<FriendsProvider>.value(value: friends),
        ChangeNotifierProvider<GymProvider>.value(value: gym),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileScreen(),
      ),
    );
  }

  testWidgets('Profile header shows avatar and no username', (tester) async {
    final auth = MockAuthProvider();
    final profile = MockProfileProvider();
    final settings = MockSettingsProvider();
    final friends = MockFriendsProvider();
    final gym = MockGymProvider();

    when(() => auth.avatarKey).thenReturn('a1');
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.userName).thenReturn('Admin');
    when(() => profile.isLoading).thenReturn(false);
    when(() => profile.error).thenReturn(null);
    when(() => profile.trainingDates).thenReturn([]);
    when(() => profile.loadTrainingDates(any())).thenAnswer((_) async {});
    when(() => settings.creatineEnabled).thenReturn(false);
    when(() => settings.load(any())).thenAnswer((_) async {});
    when(() => friends.pendingCount).thenReturn(0);
    when(() => friends.listen(any())).thenReturn(null);
    when(() => gym.currentGymId).thenReturn('g1');

    await tester.pumpWidget(
      buildScreen(
        auth: auth,
        profile: profile,
        settings: settings,
        friends: friends,
        gym: gym,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
          of: find.byType(AppBar), matching: find.byType(CircleAvatar)),
      findsOneWidget,
    );
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('tap avatar opens selector and updates image', (tester) async {
    var avatarKey = 'old';
    final auth = MockAuthProvider();
    final profile = MockProfileProvider();
    final settings = MockSettingsProvider();
    final friends = MockFriendsProvider();
    final gym = MockGymProvider();

    when(() => auth.avatarKey).thenAnswer(() => avatarKey);
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.setAvatarKey(any())).thenAnswer((invocation) async {
      avatarKey = invocation.positionalArguments.first as String;
      auth.notifyListeners();
    });
    when(() => profile.isLoading).thenReturn(false);
    when(() => profile.error).thenReturn(null);
    when(() => profile.trainingDates).thenReturn([]);
    when(() => profile.loadTrainingDates(any())).thenAnswer((_) async {});
    when(() => settings.creatineEnabled).thenReturn(false);
    when(() => settings.load(any())).thenAnswer((_) async {});
    when(() => friends.pendingCount).thenReturn(0);
    when(() => friends.listen(any())).thenReturn(null);
    when(() => gym.currentGymId).thenReturn('g1');

    await tester.pumpWidget(
      buildScreen(
        auth: auth,
        profile: profile,
        settings: settings,
        friends: friends,
        gym: gym,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profilbild ändern'));
    await tester.pumpAndSettle();

    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.text('Default'));
    await tester.pumpAndSettle();

    verify(() => auth.setAvatarKey('default')).called(1);
    final avatar = tester.widget<CircleAvatar>(find.descendant(
        of: find.byType(AppBar), matching: find.byType(CircleAvatar)));
    final image = avatar.backgroundImage as AssetImage;
    expect(image.assetName, 'assets/avatars/default.png');
  });
}
