import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:tapem/l10n/app_localizations.dart';
import '../../../../app_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String oobCode;
  const ResetPasswordScreen({Key? key, required this.oobCode}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _password = '';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await fb_auth.FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordResetSuccess)),
      );
      Navigator.of(context).pushReplacementNamed(AppRouter.auth);
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.resetPasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: loc.newPasswordFieldLabel, errorText: _error),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : loc.passwordTooShort,
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(loc.confirmPasswordButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
