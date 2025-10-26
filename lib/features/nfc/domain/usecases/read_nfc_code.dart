import '../../data/nfc_service.dart';

/// UseCase: liefert exakt den Stream aller gescannten Codes.
class ReadNfcCode {
  final NfcService _service;
  Stream<String>? _cachedStream;
  ReadNfcCode(this._service);

  Stream<String> execute() => _cachedStream ??= _service.readStream();
}
