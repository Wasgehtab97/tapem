// lib/features/nfc/domain/usecases/write_nfc_tag.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Schreibt den [code] als einen einzigen NDEF-Text-Record
/// (Well-Known, Typ 'T', Sprache 'en') aufs erste gefundene NFC-Tag,
/// mit Timeout und sauberem Session-Handling über nfc_manager.
class WriteNfcTagUseCase {
  /// Startet das Beschreiben des Tags.
  ///
  /// Wirft eine Exception über den Completer, wenn das Schreiben fehlschlägt.
  Future<void> execute(String code) async {
    final bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      throw Exception('NFC wird auf diesem Gerät nicht unterstützt.');
    }

    final completer = Completer<void>();

    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession(
              errorMessageIos: 'Tag unterstützt kein NDEF.',
            );
            if (!completer.isCompleted) completer.completeError(Exception('Nicht NDEF-fähig'));
            return;
          }

          if (!ndef.isWritable) {
            await NfcManager.instance.stopSession(
              errorMessageIos: 'Tag ist schreibgeschützt.',
            );
            if (!completer.isCompleted) completer.completeError(Exception('Schreibgeschützt'));
            return;
          }

          // Erstellt einen Standard NDEF Text Record (en)
          // Format: [Status(1), Lang(2), Text(n)]
          final record = _createTextRecord(code);
          final message = NdefMessage(records: [record]);

          await ndef.write(message: message);
          
          await NfcManager.instance.stopSession(
            alertMessageIos: 'Schreiben abgeschlossen',
          );
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessageIos: 'Fehler beim Schreiben: $e',
          );
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        NfcManager.instance.stopSession();
        throw TimeoutException('Zeitüberschreitung beim NFC-Scan.');
      },
    );
  }

  /// Erzeugt einen einfachen Text-Record (Well-Known / 'T') mit Sprache 'en'.
  NdefRecord _createTextRecord(String text) {
    const languageCode = 'en';
    final langBytes = utf8.encode(languageCode);
    final textBytes = utf8.encode(text);

    final statusByte = langBytes.length & 0x3F; // UTF-8, Bits 0-5 = Sprachlänge
    final payload = Uint8List.fromList([statusByte, ...langBytes, ...textBytes]);

    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList('T'.codeUnits),
      identifier: Uint8List(0),
      payload: payload,
    );
  }
}
