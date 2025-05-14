import 'nfc_service.dart';

/// Dummy-Implementierung, die keine NFC-Session startet.
class NfcServiceImpl implements NfcService {
  @override
  Future<void> startNfcSession(void Function(String tagData) onTagRead) async {
    // hier passiert nichts
    return;
  }

  @override
  Future<void> stopNfcSession() async {
    // hier passiert nichts
    return;
  }
}
