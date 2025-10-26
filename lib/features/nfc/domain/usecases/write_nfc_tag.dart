// lib/features/nfc/domain/usecases/write_nfc_tag.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ndef/ndef.dart' show TypeNameFormat;

/// Schreibt den Hex-String [hexCode] als einen einzigen NDEF-Text-Record
/// (Well-Known, Typ 'T') aufs erste gefundene NFC-Tag (ISO-14443),
/// mit Timeout und sauberem Session-Handling.
class WriteNfcTagUseCase {
  static const _channel = MethodChannel('flutter_nfc_kit');

  static const _languageCode = 'en';
  static const _pollTimeout = Duration(seconds: 10);

  /// Startet das Auslesen und Schreiben des Tags.
  ///
  /// Wirft eine Exception, wenn NFC nicht verfügbar ist oder das Schreiben fehlschlägt.
  Future<void> execute(String hexCode) async {
    // 1) Prüfen, ob NFC verfügbar ist
    if (await _nfcAvailability() != 'available') {
      throw Exception('NFC wird auf diesem Gerät nicht unterstützt.');
    }

    // 2) Polling starten (ISO-14443) mit Timeout und iOS-Hinweisen
    await _channel.invokeMethod<void>('poll', {
      'timeout': _pollTimeout.inMilliseconds,
      'iosAlertMessage': 'Bitte halte dein Gerät an den NFC-Tag',
      'iosMultipleTagMessage': 'Mehrere Tags erkannt – bitte nur ein Tag halten.',
    });

    try {
      // 3) Raw-Record bauen und schreiben
      final record = _buildRawTextRecord(hexCode);
      await _channel.invokeMethod<void>('writeNDEFRawRecords', [record]);
    } on PlatformException catch (e, st) {
      debugPrint('❌ WriteNfcTagUseCase failed: \$e');
      debugPrint(st.toString());
      rethrow;
    } finally {
      // 4) Session immer beenden
      try {
        await _channel.invokeMethod<void>('finish', {
          'iosAlertMessage': 'Schreiben abgeschlossen',
        });
      } on PlatformException catch (e) {
        debugPrint('⚠️ NFC finish() failed: \$e');
      }
    }
  }

  /// Baut ein einzelnes NDEFRawRecord im Well-Known Text-Format:
  /// - MB=1, ME=1, SR=1, TNF=0x1 → Header 0xD1
  /// - Type 'T' (0x54), Payload = StatusByte + Lang + Text
  Map<String, dynamic> _buildRawTextRecord(String text) {
    // a) Sprache und Text in UTF-8-Bytes
    final langBytes = utf8.encode(_languageCode);
    final textBytes = utf8.encode(text);

    // b) Status-Byte: bit7=0 (UTF-8), bits[5..0] = Länge der language-code Bytes
    final status = langBytes.length & 0x3F;

    // c) Payload: [Status, langBytes..., textBytes...]
    final payload = <int>[status, ...langBytes, ...textBytes];

    // d) Byte-Array als hex-String
    final payloadHex =
        payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // e) Record-Type 'T' = 0x54
    const typeHex = '54';

    return {
      'identifier': '',
      'payload': payloadHex,
      'type': typeHex,
      'typeNameFormat': TypeNameFormat.nfcWellKnown.index,
    };
  }

  Future<String?> _nfcAvailability() async {
    try {
      final result = await _channel.invokeMethod<String>('nfcAvailability');
      return result;
    } on MissingPluginException {
      // Falls der alte Kanal nicht verfügbar ist, auf den neuen Methoden-Namen
      // des Plugins zurückfallen.
      final availability = await MethodChannel('flutter_nfc_kit/method')
          .invokeMethod<String>('getNFCAvailability');
      return availability;
    }
  }
}
