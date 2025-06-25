import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/app_router.dart';

class SelectGymScreen extends StatelessWidget {
  const SelectGymScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final codes = auth.gymCodes ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Studio auswählen')),
      body: ListView.separated(
        itemCount: codes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final code = codes[i];
          return ListTile(
            title: Text('Studio: $code'),
            onTap: () async {
              await auth.setGymCode(code);
              Navigator.of(context).pushReplacementNamed(AppRouter.home);
            },
          );
        },
      ),
    );
  }
}
