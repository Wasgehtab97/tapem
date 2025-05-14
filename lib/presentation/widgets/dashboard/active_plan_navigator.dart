import 'package:flutter/material.dart';

class ActivePlanNavigator extends StatelessWidget {
  final int index, length;
  final VoidCallback onPrev, onNext, onEnd;

  const ActivePlanNavigator({
    Key? key,
    required this.index,
    required this.length,
    required this.onPrev,
    required this.onNext,
    required this.onEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: Icon(Icons.arrow_back), onPressed: onPrev),
        Text('${index + 1} / $length'),
        IconButton(icon: Icon(Icons.arrow_forward), onPressed: onNext),
        TextButton(child: Text('Beenden'), onPressed: onEnd),
      ],
    );
  }
}
