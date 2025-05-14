import 'package:flutter/material.dart';

class FinishAndNextButtons extends StatelessWidget {
  final VoidCallback onNext, onFinish;
  final bool isFinishDisabled;

  const FinishAndNextButtons({
    Key? key,
    required this.onNext,
    required this.onFinish,
    this.isFinishDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(onPressed: onNext, child: Text('Weiter')),
        ElevatedButton(
          onPressed: isFinishDisabled ? null : onFinish,
          child: Text('Beenden'),
        ),
      ],
    );
  }
}
