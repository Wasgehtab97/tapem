import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/util/duration_utils.dart';

void main() {
  test('parseHms handles hh:mm:ss', () {
    expect(parseHms('00:00:59'), 59);
    expect(parseHms('01:02:03'), 3723);
    expect(parseHms('00:59:59'), 3599);
    expect(parseHms(''), 0);
    expect(parseHms('xx'), 0);
  });

  test('parseHms handles seconds', () {
    expect(parseHms('90'), 90);
  });

  test('formatHms produces hh:mm:ss', () {
    expect(formatHms(3723), '01:02:03');
    expect(formatHms(59), '00:00:59');
  });
}
