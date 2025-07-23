import 'package:flutter/material.dart';

class ExperienceScreen extends StatelessWidget {
  final String userName;
  const ExperienceScreen({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final users = List.generate(
      10,
      (i) => {'name': 'User ${i + 1}', 'xp': 100 - i * 5},
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Erfahrung')),
      body: Column(
        children: [
          ListTile(title: Text(userName)),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return ListTile(
                  leading: Text('#${i + 1}'),
                  title: Text(u['name'] as String),
                  trailing: Text('${u['xp']} XP'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
