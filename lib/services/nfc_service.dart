/// Abstraktes NFC-Service, das eine Session startet und alle
/// eingelesenen Tag-Daten an einen Callback weiterreicht.
abstract class NfcService {
  /// Startet eine NFC-Session und liefert jedes Mal, wenn ein
  /// Tag eingelesen wird, den Roh-String an [onTagRead].
  Future<void> startNfcSession(void Function(String tagData) onTagRead);

  /// Optional: Beende eine laufende Session.
  Future<void> stopNfcSession();
}
