import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tapem/features/nfc/presentation/screens/nfc_write_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc  = AppLocalizations.of(context)!;
    if (auth.role != 'admin') {
      return Center(child: Text(loc.noAdminRights));
    }
    return Scaffold(
      appBar: AppBar(title: Text(loc.adminTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // bestehende Widgets…
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.nfc),
            label: Text(loc.nfcWriteTag),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NfcWriteScreen(
                    gymId: auth.gymCode!,
                    deviceId: '<<hier Device-ID auswählen>>',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
