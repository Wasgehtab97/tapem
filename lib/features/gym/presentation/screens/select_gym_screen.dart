import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';

class SelectGymScreen extends StatelessWidget {
  const SelectGymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gyms = context.watch<AuthProvider>().gymCodes ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Gym auswählen')),
      body: ListView.separated(
        itemCount: gyms.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final code = gyms[i];
          return ListTile(
            title: Text(code),
            onTap: () async {
              await context.read<AuthProvider>().selectGym(code);
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRouter.home, arguments: 1);
              }
            },
          );
        },
      ),
    );
  }
}
