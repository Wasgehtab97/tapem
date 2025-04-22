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
  Widget build(BuildContext ctx) {
    if (length < 2) return const SizedBox();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: index>0?onPrev:null, child: const Text("←")),
              ElevatedButton(onPressed: onEnd, child: const Text("Ende")),
              ElevatedButton(onPressed: index<length-1?onNext:null, child: const Text("→")),
            ],
          ),
          Text("Übung ${index+1} von $length"),
        ]),
      ),
    );
  }
}
