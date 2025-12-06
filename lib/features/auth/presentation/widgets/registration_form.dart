import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/features/gym/domain/models/gym_code_validation_result.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';

class RegistrationForm extends StatefulWidget {
  final ValidateGymCode? gymValidator;

  const RegistrationForm({Key? key, this.gymValidator}) : super(key: key);

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _gymController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _gymError;
  int _attempts = 0;
  bool _isLocked = false;
  Timer? _lockTimer;
  static const _maxAttempts = 3;
  static const _lockDuration = Duration(seconds: 30);
  late final ValidateGymCode _validateGymCode;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _validateGymCode = widget.gymValidator ?? ValidateGymCode();
  }

  @override
  void dispose() {
    _gymController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLocked) return;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _gymError = null;
      _isValidating = true;
    });

    try {
      final gymCode = _gymController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Validate gym code (now returns GymCodeValidationResult)
      final validation = await _validateGymCode.execute(gymCode);
      
      // Show warning if code is expiring soon
      if (validation.isExpiringSoon && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note: This code expires in ${validation.daysUntilExpiration} days. '
              'Get the new code from your gym after that.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Proceed with registration
      final authProv = context.read<AuthProvider>();
      final loc = AppLocalizations.of(context)!;
      final result = await authProv.register(email, password, gymCode);
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

    } on GymCodeExpiredException {
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = 'Code expired. Please get the current code from your gym.';
      });
      _handleFailedAttempt();
    } on GymCodeNotFoundException {
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = AppLocalizations.of(context)!.gymCodeInvalid;
      });
      _handleFailedAttempt();
    } on GymCodeInactiveException {
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = 'This code is no longer active. Please get a new code.';
      });
      _handleFailedAttempt();
    } on InvalidCodeFormatException {
      if (!mounted) return;
      setState(() {
        _gymError = 'Invalid code format. Code must be 6 characters.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gymError = 'Error validating code: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _handleFailedAttempt() {
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.gymCodeHelpLabel,
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
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
            textInputAction: TextInputAction.next,
            validator: (v) => v != null && v.length >= 6 ? null : loc.passwordTooShort,
          ),
          const SizedBox(height: AuthTheme.spacingM),
          
          PremiumTextField(
            label: loc.gymCodeFieldLabel,
            controller: _gymController,
            prefixIcon: Icons.fitness_center_outlined,
            textInputAction: TextInputAction.done,
            // Convert to uppercase automatically
            onChanged: (val) {
              final upper = val.toUpperCase();
              if (val != upper) {
                _gymController.value = _gymController.value.copyWith(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            },
            validator: (v) {
              if (_isLocked) return AppLocalizations.of(context)!.gymCodeLockedMessage;
              if (v == null || v.length != 6) return loc.gymCodeInvalid;
              return _gymError; // Show specific gym error if set
            },
          ),
          if (_gymError != null && !_isLocked)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                _gymError!,
                style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
              ),
            ),
            
          const SizedBox(height: AuthTheme.spacingL),
          
          PremiumButton(
            text: _isLocked 
                ? 'Locked (${(_lockDuration.inSeconds).toString()}s)' 
                : loc.registerButton,
            isLoading: authProv.isLoading || _isValidating,
            onPressed: (authProv.isLoading || _isValidating || _isLocked) 
                ? null 
                : _submit,
          ),
        ],
      ),
    );
  }
}
