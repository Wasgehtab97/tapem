import 'package:flutter/material.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/ui/timer/timer_app_bar_title.dart';

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
        centerTitle: true,
        title: TimerAppBarTitle(
          centerTitle: true,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              title,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        actions: const [
          NfcScanButton(), // Button-getriggertes NFC-Scanning
          SizedBox(width: 8),
        ],
      ),
      body: child,
    );
  }
}
