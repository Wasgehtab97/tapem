import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/auth_providers.dart';

Future<void> showUsernameDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final ctr = TextEditingController();
  final container = ProviderScope.containerOf(context, listen: false);
  final AuthProvider auth = container.read(authControllerProvider);
  String? error;
  bool loading = false;
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        final theme = Theme.of(ctx);
        final brandTheme = theme.extension<AppBrandTheme>();
        final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
        final canSubmit = ctr.text.trim().isNotEmpty && !loading;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: BrandModalSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandModalHeader(
                  icon: Icons.person_rounded,
                  accent: brandColor,
                  title: loc.usernameDialogTitle,
                  subtitle: loc.usernameHelper,
                  onClose: loading ? null : () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctr,
                  enabled: !loading,
                  autofocus: true,
                  onChanged: (_) => setState(() {
                    if (error != null) error = null;
                  }),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) async {
                    final name = ctr.text.trim();
                    if (name.isEmpty || loading) return;
                    setState(() => loading = true);
                    final success = await auth.setUsername(name);
                    if (!ctx.mounted) return;
                    if (success) {
                      Navigator.pop(ctx);
                      return;
                    }
                    setState(() {
                      loading = false;
                      error = auth.error ?? loc.usernameTaken;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: loc.usernameFieldLabel,
                    errorText: error,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: brandColor.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: loading ? null : () => Navigator.pop(ctx),
                        child: Text(loc.cancelButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BrandPrimaryButton(
                        onPressed: canSubmit
                            ? () async {
                                final name = ctr.text.trim();
                                if (name.isEmpty) return;
                                setState(() => loading = true);
                                final success = await auth.setUsername(name);
                                if (!ctx.mounted) return;
                                if (success) {
                                  Navigator.pop(ctx);
                                } else {
                                  setState(() {
                                    loading = false;
                                    error = auth.error ?? loc.usernameTaken;
                                  });
                                }
                              }
                            : null,
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                loc.commonOk,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  ctr.dispose();
}
