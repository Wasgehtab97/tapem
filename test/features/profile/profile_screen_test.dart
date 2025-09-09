import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/features/friends/data/friends_api.dart';
import 'package:tapem/features/friends/data/friends_source.dart';
import 'package:tapem/features/friends/data/user_search_source.dart';
import 'package:tapem/features/friends/domain/models/friend.dart';
import 'package:tapem/features/friends/domain/models/friend_request.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';
import 'package:tapem/features/friends/providers/friend_search_provider.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeProfileProvider extends ProfileProvider {
  @override
  Future<void> loadTrainingDates(BuildContext context) async {}
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  bool _creatine = false;

  @override
  bool get creatineEnabled => _creatine;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> load(String uid) async {}

  @override
  Future<void> setCreatineEnabled(bool value) async {
    _creatine = value;
    notifyListeners();
  }
}

class FakeFriendsSource implements FriendsSource {
  @override
  Stream<List<Friend>> watchFriends(String meUid) => const Stream.empty();

  @override
  Stream<List<FriendRequest>> watchIncoming(String meUid) => const Stream.empty();

  @override
  Stream<List<FriendRequest>> watchOutgoing(String meUid) => const Stream.empty();

  @override
  Stream<List<FriendRequest>> watchOutgoingAccepted(String meUid) =>
      const Stream.empty();
}

class FakeFriendsApi implements FriendsApi {
  @override
  Future<void> sendRequest(String toUserId, {String? message}) async {}

  @override
  Future<void> cancelRequest(String toUserId) async {}

  @override
  Future<void> acceptRequest(String fromUserId) async {}

  @override
  Future<void> declineRequest(String fromUserId) async {}

  @override
  Future<void> removeFriend(String otherUserId) async {}

  @override
  Future<void> ensureFriendEdge(String otherUserId) async {}
}

class FakeFriendsProvider extends FriendsProvider {
  FakeFriendsProvider() : super(FakeFriendsSource(), FakeFriendsApi());

  @override
  void listen(String meUid) {}
}

class FakeUserSearchSource implements UserSearchSource {
  @override
  Future<PublicProfile> getProfile(String uid) async =>
      PublicProfile(uid: uid, username: '', avatarKey: 'default');

  @override
  Stream<List<PublicProfile>> streamByUsernamePrefix(String q,
          {int limit = 20}) =>
      const Stream.empty();
}

class FakeFriendPresenceProvider extends ChangeNotifier
    implements FriendPresenceProvider {
  @override
  Map<String, PresenceState> get states => {};

  @override
  void updateUids(List<String> uids) {}

  @override
  PresenceState stateFor(String uid) => PresenceState.unknown;
}

class FakeRoute extends Fake implements Route<dynamic> {}

class FakeAvatarInventoryProvider extends AvatarInventoryProvider {
  FakeAvatarInventoryProvider(this._keys) : super();

  final List<String> _keys;

  @override
  Stream<List<String>> inventoryKeys(String uid, {String? currentGymId}) =>
      Stream.value(_keys);

  @override
  Future<Set<String>> getOwnedAvatarIds() async => _keys.toSet();

  @override
  bool isOwned(String avatarId) => _keys.contains(avatarId);
}

Future<void> pumpProfileScreen(
  WidgetTester tester,
  AuthProvider auth, {
  NavigatorObserver? observer,
  AvatarInventoryProvider? inventory,
}) async {
  final userSearch = FakeUserSearchSource();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AvatarInventoryProvider>.value(
            value: inventory ?? FakeAvatarInventoryProvider(const [])),
        ChangeNotifierProvider<ProfileProvider>(
            create: (_) => FakeProfileProvider()),
        ChangeNotifierProvider<FriendsProvider>(
            create: (_) => FakeFriendsProvider()),
        ChangeNotifierProvider<SettingsProvider>(
            create: (_) => FakeSettingsProvider()),
        ChangeNotifierProvider<GymProvider>(create: (_) => GymProvider()),
        ChangeNotifierProvider<app.AppProvider>(
            create: (_) => app.AppProvider()),
        Provider<UserSearchSource>.value(value: userSearch),
        ChangeNotifierProvider<FriendSearchProvider>(
            create: (_) => FriendSearchProvider(userSearch)),
        ChangeNotifierProvider<FriendPresenceProvider>(
            create: (_) => FakeFriendPresenceProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {AppRouter.auth: (_) => const SizedBox()},
        home: const ProfileScreen(),
        navigatorObservers: observer != null ? [observer] : [],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  testWidgets('no username row and avatar in app bar', (tester) async {
    final auth = MockAuthProvider();
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.avatarKey).thenReturn(AvatarKeys.globalDefault);
    when(() => auth.userName).thenReturn('Admin');

    await pumpProfileScreen(tester, auth);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.flexibleSpace, isNull);
    expect(appBar.title, isA<Stack>());

    expect(find.text('Admin'), findsNothing);
    expect(find.text('Trainingstage'), findsOneWidget);
    expect(find.byTooltip('Profilbild ändern'), findsOneWidget);
  });

  testWidgets('tap on avatar opens selector sheet', (tester) async {
    final auth = MockAuthProvider();
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.avatarKey).thenReturn('default');

    await pumpProfileScreen(tester, auth);

    await tester.tap(find.byTooltip('Profilbild ändern'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Avatar 1'), findsOneWidget);
    expect(find.byTooltip('Avatar 2'), findsOneWidget);
    expect(find.text('Default'), findsNothing);
  });

  testWidgets('selecting avatar updates header and persists', (tester) async {
    var key = AvatarKeys.globalDefault;
    final auth = MockAuthProvider();
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.avatarKey).thenAnswer((_) => key);
    when(() => auth.setAvatarKey(any())).thenAnswer((invocation) async {
      key = invocation.positionalArguments.first as String;
    });

    await pumpProfileScreen(tester, auth);

    await tester.tap(find.byTooltip('Profilbild ändern'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Avatar 2'));
    await tester.pumpAndSettle();

    verify(() => auth.setAvatarKey(AvatarKeys.globalDefault2)).called(1);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(
      (avatar.backgroundImage as AssetImage).assetName,
      AvatarCatalog.instance.pathForKey(AvatarKeys.globalDefault2),
    );
  });

  testWidgets('unknown avatar key falls back to default', (tester) async {
    final auth = MockAuthProvider();
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.avatarKey).thenReturn('mystery');

    await pumpProfileScreen(tester, auth);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(
      (avatar.backgroundImage as AssetImage).assetName,
      AvatarCatalog.instance.pathForKey(AvatarKeys.globalDefault),
    );
  });

  testWidgets('actions are tappable', (tester) async {
    final auth = MockAuthProvider();
    when(() => auth.userId).thenReturn('u1');
    when(() => auth.avatarKey).thenReturn(AvatarKeys.globalDefault);
    when(() => auth.logout()).thenAnswer((_) async {});

    final observer = MockNavigatorObserver();
    await pumpProfileScreen(tester, auth, observer: observer);
    reset(observer);

    await tester.tap(find.byTooltip('Freunde'));
    await tester.pumpAndSettle();
    verify(() => observer.didPush(any(), any())).called(1);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abmelden'));
    await tester.pumpAndSettle();
    verify(() => auth.logout()).called(1);
  });
}

