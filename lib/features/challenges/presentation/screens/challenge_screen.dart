import 'package:flutter/material.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_tab.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Challenges')),
      body: ChallengeTab(),
    );
  }
}
