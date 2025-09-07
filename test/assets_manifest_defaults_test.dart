import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset manifest contains required avatar defaults', () async {
    String manifestStr;
    try {
      manifestStr = await rootBundle.loadString('AssetManifest.json');
    } catch (_) {
      manifestStr = await rootBundle.loadString('AssetManifest.bin.json');
    }
    final Map<String, dynamic> manifest = json.decode(manifestStr) as Map<String, dynamic>;
    expect(manifest.containsKey('assets/avatars/global/default.png'), isTrue);
    expect(manifest.containsKey('assets/avatars/global/default2.png'), isTrue);
    expect(manifest.containsKey('assets/avatars/gym_01/kurzhantel.png'), isTrue);
  });
}
