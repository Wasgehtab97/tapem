import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Liefert einen Stream mit allen NDEF-Texten (ohne Status-/Lang-Code-Bytes),
/// die der Benutzer scannt. Nach jedem Scan wird die Session beendet
/// und kurz danach neu gestartet.
class NfcService {
  Stream<String> readStream() async* {
    while (true) {
      final completer = Completer<String>();
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (tag) async {
          String code = '';
          try {
            // Versuche, NDEF zu parsen
            final ndef = Ndef.from(tag);
            final records = ndef?.cachedMessage?.records;
            if (records != null && records.isNotEmpty) {
              // Payload: skip 3 Status-/Lang-Code-Bytes
              final payload = records.first.payload.skip(3);
              code = String.fromCharCodes(payload);
            }
          } catch (_) {
            code = '';
          } finally {
            // immer beenden, sonst bleibt das Tag “gefangen”
            await NfcManager.instance.stopSession();
          }
          completer.complete(code);
        },
      );
      final result = await completer.future;
      yield result;
      // kleines Delay, damit stopSession greifen kann
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}
