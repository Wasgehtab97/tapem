import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/auth/presentation/widgets/password_reset_dialog.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authProv = ref.read(authControllerProvider);
    final loc = AppLocalizations.of(context)!;
    
    // Manual validation since we might use controllers
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await authProv.login(email, password);
    if (!mounted) return;

    if (!result.success || authProv.error != null) {
      final message = authProv.error ?? '${loc.errorPrefix}: unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (result.missingMembership) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.missingMembershipError)),
      );
    }

    final requiresGymSelection = result.requiresGymSelection ||
        result.gymContextStatus == GymContextStatus.missingSelection;

    if (requiresGymSelection) {
      Navigator.of(context).pushReplacementNamed(AppRouter.selectGym);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.home, arguments: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = ref.watch(authControllerProvider);
    final loc = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumTextField(
            label: loc.emailFieldLabel,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) => v != null && v.contains('@') ? null : loc.emailInvalid,
          ),
          const SizedBox(height: AuthTheme.spacingM),
          PremiumTextField(
            label: loc.passwordFieldLabel,
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            validator: (v) => v != null && v.length >= 6 ? null : loc.passwordTooShort,
          ),
          const SizedBox(height: AuthTheme.spacingL),
          
          PremiumButton(
            text: loc.loginButton,
            isLoading: authProv.isLoading,
            onPressed: authProv.isLoading ? null : _submit,
          ),
          
          const SizedBox(height: AuthTheme.spacingS),
          Center(
            child: TextButton(
              onPressed: () => showPasswordResetDialog(context),
              child: Text(
                loc.forgotPassword,
                style: AuthTheme.labelStyle.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
