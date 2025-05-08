// lib/widgets/feedback_form.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/tenant/tenant_service.dart';

class FeedbackForm extends StatefulWidget {
  final int deviceId;
  final VoidCallback? onClose;
  final Function(DocumentReference)? onFeedbackSubmitted;

  const FeedbackForm({
    Key? key,
    required this.deviceId,
    this.onClose,
    this.onFeedbackSubmitted,
  }) : super(key: key);

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  String _error = '';
  String _success = '';

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final feedbackText = _feedbackController.text.trim();

    final user = FirebaseAuth.instance.currentUser;
    final gymId = TenantService().gymId;
    if (user == null || gymId == null) {
      setState(() => _error = 'Bitte zuerst anmelden und Studio auswählen.');
      return;
    }

    try {
      final ref = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('feedback')
          .add({
        'userId': user.uid,
        'deviceId': widget.deviceId,
        'text': feedbackText,
        'status': 'neu',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _success = 'Feedback erfolgreich gesendet.';
        _error = '';
      });
      _feedbackController.clear();

      widget.onFeedbackSubmitted?.call(ref);
      widget.onClose?.call();
    } catch (e) {
      setState(() => _error = 'Fehler beim Absenden des Feedbacks.');
      debugPrint('Feedback error: $e');
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback geben',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            if (_success.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _success,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.green),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Bitte geben Sie Ihr Feedback ein...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Mindestens 10 Zeichen erforderlich.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Absenden'),
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    child: const Text('Abbrechen'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
