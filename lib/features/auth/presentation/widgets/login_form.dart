import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _submit() async {
    final authProv = context.read<AuthProvider>();
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    await authProv.login(_email, _password);
    if (authProv.error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProv.error!)),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRouter.home,
      arguments: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: loc.emailFieldLabel),
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _email = v!.trim(),
              validator: (v) =>
                  v != null && v.contains('@') ? null : loc.emailInvalid,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: loc.passwordFieldLabel),
              obscureText: true,
              onSaved: (v) => _password = v ?? '',
              validator: (v) =>
                  v != null && v.length >= 6 ? null : loc.passwordTooShort,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authProv.isLoading ? null : _submit,
              child: authProv.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.loginButton),
            ),
          ],
        ),
      ),
    );
  }
}
