import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../../../core/providers/auth_provider.dart';

Future<void> showUsernameDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final ctr = TextEditingController();
  final auth = context.read<AuthProvider>();
  String? error;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => StatefulBuilder(
          builder:
              (ctx, setState) => AlertDialog(
                title: Text(loc.usernameDialogTitle),
                content: TextField(
                  controller: ctr,
                  decoration: InputDecoration(
                    labelText: loc.usernameFieldLabel,
                    errorText: error,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = ctr.text.trim();
                      if (name.isEmpty) return;
                      final success = await auth.setUsername(name);
                      if (success) {
                        debugPrint('Username "$name" successfully saved');
                        // ignore: use_build_context_synchronously
                        Navigator.pop(ctx);
                      } else {
                        debugPrint('Failed to set username "$name": '
                            '${auth.error ?? 'unknown error'}');
                        setState(() => error = auth.error ?? loc.usernameTaken);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        ),
  );
}
