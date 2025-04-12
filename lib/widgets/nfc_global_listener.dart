import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../main.dart'; // Importiere den globalen Navigator-Key

class NfcGlobalListener extends StatefulWidget {
  final Widget child;
  const NfcGlobalListener({Key? key, required this.child}) : super(key: key);

  @override
  _NfcGlobalListenerState createState() => _NfcGlobalListenerState();
}

class _NfcGlobalListenerState extends State<NfcGlobalListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startNfcListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startNfcListening();
    }
  }

  void _startNfcListening() {
    NfcService().startNfcSession((tagData) {
      final normalizedTagData = tagData.toLowerCase().trim();
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        print("Navigator nicht verfügbar.");
        return;
      }
      final theme = Theme.of(navigator.context);
      // Erwartetes Format: "id;secret_code;name"
      if (normalizedTagData.contains(";")) {
        final parts = normalizedTagData.split(";");
        if (parts.length == 3) {
          final idPart = parts[0].trim();
          final secretCode = parts[1].trim();
          final deviceName = parts[2].trim();
          final deviceId = int.tryParse(idPart);
          if (deviceId != null) {
            navigator.pushNamed(
              '/dashboard',
              arguments: {
                'deviceId': deviceId,
                'secretCode': secretCode,
                'deviceName': deviceName,
              },
            );
            return;
          } else {
            ScaffoldMessenger.of(navigator.context).showSnackBar(
              SnackBar(
                content: Text(
                  "Ungültige Geräte-ID: $idPart",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            SnackBar(
              content: Text(
                "Unerwartetes Format: $tagData",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
          return;
        }
      }

      // Fallback: Falls kein Semikolon gefunden wird, anhand von Schlüsselwörtern navigieren.
      if (normalizedTagData.contains("bankdruecken")) {
        navigator.pushNamed('/dashboard', arguments: {'exercise': 'bankdruecken'});
      } else if (normalizedTagData.contains("kniebeugen")) {
        navigator.pushNamed('/dashboard', arguments: {'exercise': 'kniebeugen'});
      } else if (normalizedTagData.contains("kreuzheben")) {
        navigator.pushNamed('/dashboard', arguments: {'exercise': 'kreuzheben'});
      } else if (normalizedTagData.contains("high row isolateral")) {
        navigator.pushNamed('/dashboard', arguments: {'exercise': 'high row isolateral'});
      } else {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Text(
              "Unbekannter NFC-Tag: $tagData",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
