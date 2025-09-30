import 'package:flutter/material.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';

/// BaseScreen: Gemeinsamer Scaffold mit AppBar-Titel und NFC-Scan-Button.
/// Alle Screens, die diese Basisklasse nutzen, erhalten automatisch den NFC-Button.
class BaseScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const BaseScreen({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          NfcScanButton(), // Button-getriggertes NFC-Scanning
        ],
      ),
      body: child,
    );
  }
}
