import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/data/repositories/gym_repository_impl.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({Key? key}) : super(key: key);

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _gymController = TextEditingController();
  String _email = '';
  String _password = '';
  String _gymCode = '';
  String? _gymError;
  int _attempts = 0;
  bool _isLocked = false;
  Timer? _lockTimer;
  static const _maxAttempts = 3;
  static const _lockDuration = Duration(seconds: 30);

  @override
  void dispose() {
    _gymController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLocked) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _gymError = null);

    final validator = ValidateGymCode(GymRepositoryImpl(FirestoreGymSource()));

    try {
      await validator.execute(_gymCode);
    } on GymNotFoundException {
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = AppLocalizations.of(context)!.gymCodeInvalid;
      });
      if (_attempts >= _maxAttempts) {
        setState(() => _isLocked = true);
        _lockTimer = Timer(_lockDuration, () {
          if (!mounted) return;
          setState(() {
            _isLocked = false;
            _attempts = 0;
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.gymCodeLockedMessage),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.gymCodeHelpLabel,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    final authProv = context.read<AuthProvider>();
    await authProv.register(_email, _password, _gymCode);
    if (authProv.error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProv.error!)));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.home, arguments: 1);
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
              validator:
                  (v) => v != null && v.contains('@') ? null : loc.emailInvalid,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: loc.passwordFieldLabel),
              obscureText: true,
              onSaved: (v) => _password = v ?? '',
              validator:
                  (v) =>
                      v != null && v.length >= 6 ? null : loc.passwordTooShort,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gymController,
              decoration: InputDecoration(
                labelText: loc.gymCodeFieldLabel,
                errorText: _gymError,
              ),
              enabled: !_isLocked,
              onSaved: (v) => _gymCode = v!.trim(),
              validator:
                  (v) =>
                      v != null && v.trim().isNotEmpty
                          ? null
                          : loc.gymCodeRequired,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authProv.isLoading || _isLocked ? null : _submit,
              child:
                  authProv.isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(loc.registerButton),
            ),
          ],
        ),
      ),
    );
  }
}
