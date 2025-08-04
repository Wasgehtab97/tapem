import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_mocks/firebase_core_mocks.dart';

Future<void> setupFirebaseMocks() async {
  setupFirebaseCoreMocks();
  await Firebase.initializeApp();
}
