import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

void main() {
  test('logs and falls back for unknown key', () {
    final catalog = AvatarCatalog.instance;
    final logs = <String?>[];
    final old = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    expect(catalog.resolvePath('mystery'),
        'assets/avatars/global/default.png');
    expect(logs.last, contains('mystery'));
    debugPrint = old;
  });

  test('legacy key normalization', () {
    final catalog = AvatarCatalog.instance;
    expect(catalog.resolvePath('default'),
        'assets/avatars/global/default.png');
    expect(catalog.resolvePath('default2'),
        'assets/avatars/global/default2.png');
  });
}
