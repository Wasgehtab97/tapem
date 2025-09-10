import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tapem/core/providers/settings_provider.dart';

void main() {
  test('load defaults creatine tracker to disabled', () async {
    final firestore = FakeFirebaseFirestore();
    final prov = SettingsProvider(firestore: firestore);
    await prov.load('u1');
    expect(prov.creatineEnabled, false);
    final doc = await firestore
        .collection('users')
        .doc('u1')
        .collection('settings')
        .doc('settings')
        .get();
    expect(doc.data()?['creatineEnabled'], false);
  });
}
