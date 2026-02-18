import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';

class AdminAccessGuard extends ConsumerWidget {
  const AdminAccessGuard({
    super.key,
    required this.child,
    this.requireAppAdmin = false,
  });

  final Widget child;
  final bool requireAppAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final hasAccess = requireAppAdmin ? auth.isAppAdmin : auth.canManageGym;
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasAccess) {
      return child;
    }

    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.adminAreaTitle)),
      body: Center(child: Text(loc.adminAreaNoPermission)),
    );
  }
}
