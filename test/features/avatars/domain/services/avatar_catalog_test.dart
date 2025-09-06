import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

void main() {
  test('resolves known and unknown keys with fallback', () {
    final catalog = AvatarCatalog.instance;
    expect(catalog.resolvePath('default'),
        'assets/avatars/global/default.png');
    expect(catalog.resolvePath('global/default2'),
        'assets/avatars/global/default2.png');
    expect(catalog.resolvePath('mystery'),
        'assets/avatars/global/default.png');
  });
}
