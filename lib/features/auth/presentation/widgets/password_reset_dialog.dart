import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';

Future<void> showPasswordResetDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => const _PasswordResetDialog(),
  );
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({Key? key}) : super(key: key);

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final container = ProviderScope.containerOf(context, listen: false);
    final AuthProvider authProv = container.read(authControllerProvider);
    final loc = AppLocalizations.of(context)!;

    final email = _emailController.text.trim();
    await authProv.resetPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (authProv.error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.passwordResetSent),
          backgroundColor: Colors.green.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.error ?? loc.errorPrefix),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: AuthTheme.animationDurationFast,
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AuthTheme.spacingL),
          child: GlassCard(
            padding: const EdgeInsets.all(AuthTheme.spacingL),
            child: Material(
              color: Colors
                  .transparent, // Need Material for text inputs to work correctly
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.forgotPassword,
                      style: AuthTheme.subHeadingStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AuthTheme.spacingL),
                    PremiumTextField(
                      label: loc.emailFieldLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : loc.emailInvalid,
                    ),
                    const SizedBox(height: AuthTheme.spacingL),
                    Row(
                      children: [
                        Expanded(
                          child: PremiumButton(
                            text: 'Cancel', // Should be localized ideally
                            isOutlined: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AuthTheme.spacingM),
                        Expanded(
                          child: PremiumButton(
                            text: 'Send',
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
