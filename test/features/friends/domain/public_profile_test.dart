import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';

void main() {
  test('computedUsernameLower falls back when field missing', () {
    final profile = PublicProfile.fromMap('u1', {'username': 'Alice'});
    expect(profile.computedUsernameLower, 'alice');
  });

  test('computedUsernameLower uses existing field', () {
    final profile =
        PublicProfile.fromMap('u1', {'username': 'Alice', 'usernameLower': 'ali'});
    expect(profile.computedUsernameLower, 'ali');
  });
}
