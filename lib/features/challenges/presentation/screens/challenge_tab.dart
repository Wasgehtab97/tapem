import 'package:flutter/material.dart';

class ChallengeTab extends StatefulWidget {
  const ChallengeTab({Key? key}) : super(key: key);

  @override
  State<ChallengeTab> createState() => _ChallengeTabState();
}

class _ChallengeTabState extends State<ChallengeTab> {
  String _selection = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _selection = 'Monthly'),
                  child: const Text('Monthly'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _selection = 'Weekly'),
                  child: const Text('Weekly'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: _selection == 'Weekly'
                ? const [
                    ListTile(title: Text('Challenge A')),
                    ListTile(title: Text('Challenge B')),
                    ListTile(title: Text('Challenge C')),
                  ]
                : const [
                    ListTile(title: Text('Challenge D')),
                    ListTile(title: Text('Challenge E')),
                    ListTile(title: Text('Challenge F')),
                  ],
          ),
        ),
      ],
    );
  }
}
