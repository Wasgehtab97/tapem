import 'package:flutter/material.dart';

class DeviceXpScreen extends StatelessWidget {
  const DeviceXpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final devices = ['Gerät A', 'Gerät B', 'Gerät C'];
    return Scaffold(
      appBar: AppBar(title: const Text('Geräte XP')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, i) {
          final d = devices[i];
          return ListTile(
            title: Text(d),
            trailing: const Text('0 XP'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView(
                  children: const [
                    ListTile(title: Text('User 1'), trailing: Text('50 XP')),
                    ListTile(title: Text('User 2'), trailing: Text('40 XP')),
                    ListTile(title: Text('User 3'), trailing: Text('30 XP')),
                    ListTile(title: Text('User 4'), trailing: Text('20 XP')),
                    ListTile(title: Text('User 5'), trailing: Text('10 XP')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
