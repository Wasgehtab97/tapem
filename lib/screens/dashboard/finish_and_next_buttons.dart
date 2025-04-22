// lib/screens/dashboard/finish_and_next_buttons.dart

import 'package:flutter/material.dart';

class FinishAndNextButtons extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final bool isFinishDisabled;

  const FinishAndNextButtons({
    Key? key,
    required this.onNext,
    required this.onFinish,
    required this.isFinishDisabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: onNext, child: const Text("Nächster Satz")),
        ElevatedButton(onPressed: isFinishDisabled ? null : onFinish, child: const Text("Fertig")),
      ],
    );
  }
}
