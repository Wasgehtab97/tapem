import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/feedback/feedback_provider.dart'
    as feedback_riverpod;
import 'package:tapem/l10n/app_localizations.dart';

class FeedbackButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final iconColor = color ?? Theme.of(context).iconTheme.color;
    return IconButton(
      icon: Icon(Icons.feedback_outlined, color: iconColor),
      tooltip: loc.feedbackTooltip,
      onPressed: () => showFeedbackDialog(
        context,
        ref,
        gymId: gymId,
        deviceId: deviceId,
      ),
    );
  }
}

Future<void> showFeedbackDialog(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  required String deviceId,
}) async {
  final loc = AppLocalizations.of(context)!;
  final TextEditingController controller = TextEditingController();

  await showDialog(
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
                final auth = ref.read(authControllerProvider);
                final userId = auth.userId ?? '';
                await ref
                    .read(feedback_riverpod.feedbackProvider)
                    .submitFeedback(
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
