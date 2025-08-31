import 'package:cloud_functions/cloud_functions.dart';

/// Provides a configured [FirebaseFunctions] instance.
class FunctionsProvider {
  FunctionsProvider._();

  static FirebaseFunctions? _instance;

  static FirebaseFunctions get instance {
    if (_instance != null) return _instance!;
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
    const useEmulator = bool.fromEnvironment('USE_FUNCTIONS_EMULATOR');
    if (useEmulator) {
      functions.useFunctionsEmulator('localhost', 5001);
    }
    _instance = functions;
    return _instance!;
  }
}
