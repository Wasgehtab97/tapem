import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
class FeedbackButton extends StatelessWidget {
  final String gymId;
  final String deviceId;
  final Color? color;

  const FeedbackButton({
    Key? key,
    required this.gymId,
    required this.deviceId,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final iconColor = color ?? Theme.of(context).iconTheme.color;
    return IconButton(
      icon: Icon(Icons.feedback_outlined, color: iconColor),
      tooltip: loc.feedbackTooltip,
      onPressed: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.feedbackDialogTitle),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: loc.feedbackPlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final auth = context.read<AuthProvider>();
                  final userId = auth.userId ?? '';
                  await context.read<FeedbackProvider>().submitFeedback(
                    gymId: gymId,
                    deviceId: deviceId,
                    userId: userId,
                    text: text,
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.feedbackSent)),
                  );
                }
              },
              child: Text(loc.feedbackSubmit),
            ),
          ],
        );
      },
    );
  }
}
