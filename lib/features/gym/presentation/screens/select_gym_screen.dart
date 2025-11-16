import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SelectGymScreen extends StatelessWidget {
  const SelectGymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gyms = auth.gymCodes ?? [];
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final error = auth.error;

    Widget body;
    if (auth.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${loc.errorPrefix}: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: gyms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final code = gyms[i];
                return ListTile(
                  title: Text(code),
                  onTap: () async {
                    try {
                      await context.read<AuthProvider>().switchGym(code);
                      if (!context.mounted) return;
                      Navigator.of(context)
                          .pushReplacementNamed(AppRouter.home, arguments: 1);
                    } catch (_) {
                      if (!context.mounted) return;
                      final latestError =
                          context.read<AuthProvider>().error ?? loc.errorPrefix;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${loc.errorPrefix}: $latestError'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.selectGymTitle)),
      body: body,
    );
  }
}
