import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/theme/brand_theme_preset.dart';

Future<void> pumpEventQueue([int times = 10]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemePreferenceProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setTheme persists override locally and remotely', () async {
      final prefs = await SharedPreferences.getInstance();
      final firestore = FakeFirebaseFirestore();
      final provider = ThemePreferenceProvider(
        firestore: firestore,
        preferences: prefs,
      );

      provider.setUser('uid');
      await pumpEventQueue();

      await provider.setTheme(BrandThemeId.magentaViolet);

      expect(prefs.getString('theme_override_uid'), 'magentaViolet');
      final doc = await firestore
          .collection('users')
          .doc('uid')
          .collection('settings')
          .doc('theme')
          .get();
      expect(doc.data()?['themeId'], 'magentaViolet');
    });

    test('cached override is used until remote data is available', () async {
      SharedPreferences.setMockInitialValues({
        'theme_override_uid': 'redOrange',
      });
      final prefs = await SharedPreferences.getInstance();
      final completer = Completer<Map<String, dynamic>?>();
      final firestore = FakeFirebaseFirestore();
      final provider = ThemePreferenceProvider(
        firestore: firestore,
        preferences: prefs,
        fetchOverride: (_) => completer.future,
      );

      provider.setUser('uid');
      await pumpEventQueue();

      expect(provider.override, BrandThemeId.redOrange);
      expect(provider.hasLoaded, isFalse);

      completer.complete({'themeId': 'magentaViolet'});
      await pumpEventQueue();

      expect(provider.override, BrandThemeId.magentaViolet);
      expect(provider.hasLoaded, isTrue);
    });
  });
}
