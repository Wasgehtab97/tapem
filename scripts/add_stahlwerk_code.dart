// scripts/add_stahlwerk_code.dart
// Quick script to add Stahlwerk_dev code using Flutter's Firebase connection

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tapem/firebase_options_dev.dart';

Future<void> main() async {
  print('🚀 Adding Stahlwerk_dev code to Firebase...\n');

  // Initialize Firebase with dev config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    // Code details
    const gymId = 'Stahlwerk_dev';
    const code = 'MCHQMB';
    final now = DateTime.now();
    final expiresAt = DateTime(now.year, now.month + 1, now.day);

    print('Creating code for Stahlwerk_dev:');
    print('  Code: $code');
    print('  Expires: ${expiresAt.toIso8601String()}');
    print('');

    // Add code to Firestore
    await firestore
        .collection('gym_codes')
        .doc(gymId)
        .collection('codes')
        .add({
      'code': code,
      'gymId': gymId,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': true,
      'createdBy': 'flutter-script',
    });

    print('✅ Code successfully added to Firebase!');
    print('');
    print('You can now register with:');
    print('  Gym: Stahlwerk Dev');
    print('  Code: $code');
    print('');
  } catch (e) {
    print('❌ Error adding code: $e');
  }
}
