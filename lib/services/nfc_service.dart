import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  // Singleton-Implementierung
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isScanning = false;

  /// Startet eine NFC-Sitzung und ruft [onTagScanned] auf, wenn ein Tag entdeckt wird.
  Future<void> startNfcSession(Function(String tagData) onTagScanned) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      print("NFC ist nicht verfügbar.");
      return;
    }

    if (_isScanning) return;
    _isScanning = true;

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        String tagData = _extractTagData(tag);
        onTagScanned(tagData);
        NfcManager.instance.stopSession();
        _isScanning = false;
      },
      onError: (error) async {
        print("NFC-Fehler: $error");
        NfcManager.instance.stopSession(errorMessage: error.toString());
        _isScanning = false;
      },
    );
  }

  /// Extrahiert den Text aus einem NDEF-Tag und entfernt den Sprachcode.
  String _extractTagData(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef != null && ndef.cachedMessage != null) {
      return ndef.cachedMessage!.records.map((record) {
        final payload = record.payload;
        if (payload.isNotEmpty) {
          // Das erste Byte gibt die Länge des Sprachcodes an.
          final languageCodeLength = payload[0];
          // Überspringe das erste Byte und den Sprachcode.
          return String.fromCharCodes(payload.sublist(1 + languageCodeLength));
        }
        return "";
      }).join(",");
    }
    return tag.data.toString();
  }
}
