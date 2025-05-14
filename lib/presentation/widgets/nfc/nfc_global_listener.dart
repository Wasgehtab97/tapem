import 'package:flutter/material.dart';
import 'package:tapem/services/nfc_service_impl.dart';
import 'package:tapem/main.dart';

/// Hört global auf NFC-Tags und navigiert entsprechend weiter.
class NfcGlobalListener extends StatefulWidget {
  final Widget child;

  const NfcGlobalListener({Key? key, required this.child}) : super(key: key);

  @override
  _NfcGlobalListenerState createState() => _NfcGlobalListenerState();
}

class _NfcGlobalListenerState extends State<NfcGlobalListener>
    with WidgetsBindingObserver {
  late final NfcServiceImpl _nfcService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nfcService = NfcServiceImpl();
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
    _nfcService.startNfcSession((String tagData) {
      final normalized = tagData.toLowerCase().trim();
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      final ctx = navigator.context;
      final theme = Theme.of(ctx);

      // Wenn Format "id;secret;name"
      if (normalized.contains(';')) {
        final parts = normalized.split(';');
        if (parts.length == 3) {
          final idPart = parts[0].trim();
          final secret = parts[1].trim();
          final name = parts[2].trim();
          final deviceId = int.tryParse(idPart);
          if (deviceId != null) {
            navigator.pushNamed(
              '/dashboard',
              arguments: {
                'deviceId': deviceId,
                'secretCode': secret,
                'deviceName': name,
              },
            );
            return;
          }
          _showSnack(ctx, theme, 'Ungültige Geräte-ID: $idPart');
          return;
        }
        _showSnack(ctx, theme, 'Unerwartetes Tag-Format: $tagData');
        return;
      }

      // Fallback nach Stichwort
      const map = {
        'bankdruecken': 'bankdruecken',
        'kniebeugen': 'kniebeugen',
        'kreuzheben': 'kreuzheben',
        'high row isolateral': 'high row isolateral',
      };
      for (final entry in map.entries) {
        if (normalized.contains(entry.key)) {
          navigator.pushNamed('/dashboard', arguments: {'exercise': entry.value});
          return;
        }
      }

      _showSnack(ctx, theme, 'Unbekannter NFC-Tag: $tagData');
    });
  }

  void _showSnack(BuildContext ctx, ThemeData theme, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message, style: theme.textTheme.bodyMedium)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
