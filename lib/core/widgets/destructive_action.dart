import 'dart:async';

import 'package:flutter/material.dart';

Future<bool> showDestructiveActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Löschen',
  String cancelLabel = 'Abbrechen',
  String? auditHint,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (auditHint != null && auditHint.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.policy_outlined,
                  size: 18,
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.75),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    auditHint,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

void showUndoSnackBar({
  required BuildContext context,
  required String message,
  required Future<void> Function() onUndo,
  String undoLabel = 'Rückgängig',
  String? undoSuccessMessage,
  String? undoErrorPrefix,
  Duration duration = const Duration(seconds: 5),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      content: Text(message),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () {
          unawaited(() async {
            try {
              await onUndo();
              if (undoSuccessMessage != null &&
                  undoSuccessMessage.trim().isNotEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(undoSuccessMessage)),
                );
              }
            } catch (error) {
              if (undoErrorPrefix != null &&
                  undoErrorPrefix.trim().isNotEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$undoErrorPrefix: $error')),
                );
              }
            }
          }());
        },
      ),
    ),
  );
}
