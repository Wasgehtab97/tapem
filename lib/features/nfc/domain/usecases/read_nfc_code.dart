import '../../data/nfc_service.dart';

/// UseCase: liefert exakt den Stream aller gescannten Codes.
class ReadNfcCode {
  final NfcService _service;
  late final Stream<String> _stream;

  ReadNfcCode(this._service) {
    _stream = _service.readStream();
  }

  Stream<String> execute() => _stream;
}
