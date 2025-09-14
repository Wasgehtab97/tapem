import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/models/device.dart';

void main() {
  test('device isCardio defaults to false', () {
    final d = Device(uid: 'u', id: 1, name: 'n');
    expect(d.isCardio, false);
  });

  test('device json roundtrip keeps isCardio', () {
    final d = Device(uid: 'u', id: 1, name: 'n', isCardio: true);
    final json = d.toJson();
    final copy = Device.fromJson({...json, 'uid': 'u'});
    expect(copy.isCardio, true);
  });
}
