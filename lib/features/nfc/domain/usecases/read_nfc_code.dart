import '../../data/nfc_service.dart';

class ReadNfcCode {
  final NfcService _service;
  ReadNfcCode(this._service);

  void execute(void Function(String) onCodeRead) =>
      _service.startReadSession(onCodeRead);
}
