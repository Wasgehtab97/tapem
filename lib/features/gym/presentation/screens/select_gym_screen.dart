import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SelectGymScreen extends StatefulWidget {
  const SelectGymScreen({super.key});

  @override
  State<SelectGymScreen> createState() => _SelectGymScreenState();
}

class _SelectGymScreenState extends State<SelectGymScreen> {
  String? _claimingGymCode;
  String? _localErrorMessage;

  String? _mapError(AppLocalizations loc, String? code) {
    switch (code) {
      case 'invalid_gym_code':
        return loc.invalidGymSelectionError;
      case 'membership_sync_failed':
        return loc.membershipSyncError;
      case 'missing_membership':
        return loc.missingMembershipError;
      default:
        return code;
    }
  }

  Future<void> _selectGym(String code) async {
    if (_claimingGymCode != null) return;
    setState(() {
      _claimingGymCode = code;
      _localErrorMessage = null;
    });
    final result = await context.read<AuthProvider>().switchGym(code);
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home, arguments: 1);
    } else {
      final loc = AppLocalizations.of(context)!;
      final latestError = _mapError(loc, result.error) ??
          loc.membershipSyncError;
      setState(() => _localErrorMessage = latestError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(latestError)),
      );
    }
    if (mounted) {
      setState(() {
        _claimingGymCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gyms = auth.gymCodes ?? [];
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final errorMessage = _localErrorMessage;
    final isInitialLoading = auth.isLoading && _claimingGymCode == null && gyms.isEmpty;

    Widget body;
    if (isInitialLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (gyms.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    loc.missingMembershipError,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: gyms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final code = gyms[i];
                  final isProcessing = _claimingGymCode == code;
                  return ListTile(
                    title: Text(code),
                    trailing: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    enabled: !auth.isLoading || isProcessing,
                    onTap: auth.isLoading && !isProcessing
                        ? null
                        : () => _selectGym(code),
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
