import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';

class FeedbackButton extends StatelessWidget {
  final String deviceId;

  const FeedbackButton({Key? key, required this.deviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.feedback_outlined),
      tooltip: 'Feedback',
      onPressed: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Feedback'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Dein Feedback...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final auth = context.read<AuthProvider>();
                  final gym = context.read<GymProvider>().currentGym;
                  final userId = auth.user?.uid ?? '';
                  final gymId = gym.uid;
                  await context.read<FeedbackProvider>().submitFeedback(
                    gymId: gymId,
                    deviceId: deviceId,
                    userId: userId,
                    text: text,
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback gesendet')),
                  );
                }
              },
              child: const Text('Senden'),
            ),
          ],
        );
      },
    );
  }
}
