import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_keyboard_scroll_view.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../../../app_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String oobCode;

  const ResetPasswordScreen({super.key, required this.oobCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final password = _passwordController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await fb_auth.FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordResetSuccess),
          backgroundColor: AuthTheme.surfaceRaised,
        ),
      );
      Navigator.of(context).pushReplacementNamed(AppRouter.auth);
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: AuthKeyboardScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AuthTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AuthTheme.textMuted,
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRouter.auth),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.resetPasswordTitle,
                textAlign: TextAlign.center,
                style: AuthTheme.headingStyle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: AuthTheme.spacingS),
              Text(
                loc.forgotPassword,
                textAlign: TextAlign.center,
                style: AuthTheme.bodyStyle,
              ),
              const SizedBox(height: AuthTheme.spacingL),
              GlassCard(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumTextField(
                        label: loc.newPasswordFieldLabel,
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          return v != null && v.length >= 6
                              ? null
                              : loc.passwordTooShort;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AuthTheme.danger,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: AuthTheme.spacingL),
                      PremiumButton(
                        text: loc.confirmPasswordButton,
                        isLoading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
