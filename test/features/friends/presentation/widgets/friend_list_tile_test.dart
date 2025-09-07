import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

void main() {
  testWidgets('renders avatar and status dot', (tester) async {
    const profile = PublicProfile(
      uid: '1',
      username: 'Alice',
      avatarKey: 'default',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FriendListTile(
          profile: profile,
          presence: PresenceState.workedOutToday,
          onTap: () {},
        ),
      ),
    );
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(
      (avatar.backgroundImage as AssetImage).assetName,
      AvatarCatalog.instance.resolvePath('default'),
    );
    expect(find.byKey(const ValueKey('status-dot')), findsOneWidget);
  });

  testWidgets('updates when avatar key changes', (tester) async {
    const profile1 = PublicProfile(
      uid: '1',
      username: 'Alice',
      avatarKey: 'default',
    );
    const profile2 = PublicProfile(
      uid: '1',
      username: 'Alice',
      avatarKey: 'default2',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FriendListTile(
          profile: profile1,
          presence: PresenceState.workedOutToday,
          onTap: () {},
        ),
      ),
    );
    var avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(
      (avatar.backgroundImage as AssetImage).assetName,
      AvatarCatalog.instance.resolvePath('default'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FriendListTile(
          profile: profile2,
          presence: PresenceState.workedOutToday,
          onTap: () {},
        ),
      ),
    );
    avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(
      (avatar.backgroundImage as AssetImage).assetName,
      AvatarCatalog.instance.resolvePath('default2'),
    );
  });

  testWidgets('falls back to default for unknown key', (tester) async {
    const profile = PublicProfile(
      uid: '1',
      username: 'Alice',
      avatarKey: 'mystery',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FriendListTile(
          profile: profile,
          presence: PresenceState.workedOutToday,
          onTap: () {},
        ),
      ),
    );
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(
      (avatar.backgroundImage as AssetImage).assetName,
      AvatarCatalog.instance.resolvePath('default'),
    );
  });
}
