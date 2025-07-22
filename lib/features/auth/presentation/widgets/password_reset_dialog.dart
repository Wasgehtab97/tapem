import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/providers/auth_provider.dart';

Future<void> showPasswordResetDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final ctr = TextEditingController();
  final auth = context.read<AuthProvider>();
  String? error;
  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(loc.passwordResetDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.passwordResetHint),
            TextField(
              controller: ctr,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: loc.emailFieldLabel,
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = ctr.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setState(() => error = loc.emailInvalid);
                return;
              }
              await auth.resetPassword(email);
              if (auth.error == null) {
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.passwordResetSent)),
                );
              } else {
                setState(() => error = auth.error);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}
