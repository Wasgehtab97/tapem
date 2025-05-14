// lib/presentation/widgets/common/error_dialog.dart

import 'package:flutter/material.dart';

/// Zeigt einen einfachen Fehlerdialog mit [message] und einem „OK“-Button.
class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fehler'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
