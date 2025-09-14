import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/util/duration_utils.dart';

void main() {
  test('parseHms handles hh:mm:ss', () {
    expect(parseHms('00:00:59'), 59);
    expect(parseHms('01:02:03'), 3723);
  });

  test('parseHms handles seconds', () {
    expect(parseHms('90'), 90);
  });
}
