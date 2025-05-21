import '../../data/nfc_service.dart';

class WriteNfcCode {
  final NfcService _service;
  WriteNfcCode(this._service);

  Future<void> execute(String code) => _service.writeCode(code);
}
