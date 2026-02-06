import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Liefert einen Stream mit allen NDEF-Texten (ohne Status-/Lang-Code-Bytes),
/// die der Benutzer scannt. Nach jedem Scan wird die Session beendet
/// und kurz danach neu gestartet.
class NfcService {
  /// Hilfsmethode zum Parsen eines NDEF Text Records.
  /// Überspringt die ersten 3 Bytes (Status + Language Code "en").
  static String parseTextRecord(NdefRecord record) {
    try {
      if (record.typeNameFormat != TypeNameFormat.wellKnown) return '';
      if (String.fromCharCodes(record.type) != 'T') return '';

      final payload = record.payload;
      if (payload.isEmpty) return '';

      final status = payload.first;
      final langLength = status & 0x3F; // Bits 0-5 enthalten die Sprachcode-Länge
      final textBytes = payload.skip(1 + langLength).toList();
      if (textBytes.isEmpty) return '';

      return utf8.decode(textBytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  Stream<String> readStream() async* {
    while (true) {
      if (!(await NfcManager.instance.isAvailable())) {
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      final completer = Completer<String>();

      try {
        await NfcManager.instance.startSession(
          pollingOptions: {NfcPollingOption.iso14443},
          onDiscovered: (tag) async {
            String code = '';
            try {
              final ndef = Ndef.from(tag);
              final records = ndef?.cachedMessage?.records;
              if (records != null && records.isNotEmpty) {
                code = parseTextRecord(records.first);
              }
            } catch (_) {
              code = '';
            } finally {
              await NfcManager.instance.stopSession();
            }
            if (!completer.isCompleted) completer.complete(code);
          },
        );
      } catch (e) {
        if (!completer.isCompleted) completer.complete('');
      }

      final result = await completer.future;
      if (result.isNotEmpty) {
        yield result;
      }
      
      // Kleines Delay vor dem nächsten Scan-Versuch
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
