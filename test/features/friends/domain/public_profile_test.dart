import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';

void main() {
  test('safeLower falls back when field missing', () {
    final profile = PublicProfile.fromMap('u1', {'username': 'Alice'});
    expect(profile.safeLower, 'alice');
  });

  test('safeLower uses existing field', () {
    final profile =
        PublicProfile.fromMap('u1', {'username': 'Alice', 'usernameLower': 'ali'});
    expect(profile.safeLower, 'ali');
  });
}
