import 'package:flutter/material.dart';

class FeedbackForm extends StatelessWidget {
  final String deviceId;
  final VoidCallback onClose;

  const FeedbackForm({
    Key? key,
    required this.deviceId,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Column(
      children: [
        Text('Feedback für Gerät $deviceId'),
        TextFormField(decoration: InputDecoration(labelText: 'Kommentar')),
        ElevatedButton(onPressed: onClose, child: Text('Schließen')),
      ],
    );
  }
}
