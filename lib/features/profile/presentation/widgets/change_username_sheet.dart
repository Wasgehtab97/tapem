import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

Future<void> showChangeUsernameSheet(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final ctr = TextEditingController(text: auth.userName ?? '');
  final regex = RegExp(r'^(?!_)(?!.*__)[A-Za-z0-9_]{3,20}(?<!_)$');
  String? error;
  bool available = false;
  bool isValid(String v) => regex.hasMatch(v);
  Timer? debouncer;
  bool loading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> check(String value) async {
          final name = value.trim();
          if (!isValid(name)) {
            setState(() {
              error = name.isEmpty ? null : loc.usernameInvalid;
              available = false;
            });
            return;
          }
          setState(() {
            error = null;
          });
          final free = await auth.checkUsernameAvailable(name);
          setState(() {
            available = free;
            if (!free) error = loc.usernameTaken;
          });
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.usernameDialogTitle, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: ctr,
                autofocus: true,
                onChanged: (v) {
                  debouncer?.cancel();
                  debouncer = Timer(const Duration(milliseconds: 300), () => check(v));
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: loc.usernameFieldLabel,
                  helperText: error == null ? loc.usernameHelper : null,
                  errorText: error,
                ),
              ),
              const SizedBox(height: 8),
              if (ctr.text.isNotEmpty)
                Text(loc.usernameLowerPreview(ctr.text.toLowerCase())),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(ctx),
                    child: Text(loc.cancelButton),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (!loading && available && isValid(ctr.text))
                        ? () async {
                            setState(() => loading = true);
                            final success = await auth.setUsername(ctr.text.trim());
                            if (success) {
                              // ignore: use_build_context_synchronously
                              Navigator.pop(ctx);
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.saveSuccess)),
                              );
                            } else {
                              setState(() {
                                loading = false;
                                error = auth.error ?? loc.usernameTaken;
                              });
                            }
                          }
                        : null,
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.saveButton),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
