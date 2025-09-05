import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';

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
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byKey(const ValueKey('status-dot')), findsOneWidget);
  });
});
