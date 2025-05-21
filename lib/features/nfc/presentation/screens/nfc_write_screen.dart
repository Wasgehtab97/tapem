import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../data/nfc_service.dart';
import '../../../domain/usecases/write_nfc_code.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NfcWriteScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  const NfcWriteScreen({
    Key? key,
    required this.gymId,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends State<NfcWriteScreen> {
  late final WriteNfcCode _usecase;
  String _code = '';

  @override
  void initState() {
    super.initState();
    final svc = NfcService();
    _usecase = WriteNfcCode(svc);
    _generateCode();
  }

  void _generateCode() {
    // z.B. 16-stelliger Hex-String
    final rnd = Random.secure();
    _code = List.generate(16, (_) => rnd.nextInt(16).toRadixString(16))
        .join()
        .toUpperCase();
    setState(() {});
  }

  Future<void> _writeTag() async {
    try {
      await _usecase.execute(_code);
      // Firestore aktualisieren
      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('devices')
          .doc(widget.deviceId)
          .update({'nfcCode': _code});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC-Tag beschrieben')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC-Tag beschreiben')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Code: $_code', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Neuer Code'),
              onPressed: _generateCode,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.nfc),
              label: const Text('Auf Tag schreiben'),
              onPressed: _writeTag,
            ),
          ],
        ),
      ),
    );
  }
}
