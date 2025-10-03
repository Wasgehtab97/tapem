import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SelectGymScreen extends StatelessWidget {
  const SelectGymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gyms = context.watch<AuthProvider>().gymCodes ?? [];
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.selectGymTitle)),
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
