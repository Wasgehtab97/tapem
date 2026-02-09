import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/features/gym/domain/models/gym_code_validation_result.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';

class RegistrationForm extends ConsumerStatefulWidget {
  final ValidateGymCode? gymValidator;
  final String? initialGymCode;
  final bool gymCodeReadOnly;
  final String? expectedGymId;

  const RegistrationForm({
    Key? key,
    this.gymValidator,
    this.initialGymCode,
    this.gymCodeReadOnly = false,
    this.expectedGymId,
  }) : super(key: key);

  @override
  ConsumerState<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _gymController = TextEditingController();
  final _gymFocusNodes = List.generate(6, (_) => FocusNode());
  final _gymDigitControllers = List.generate(6, (_) => TextEditingController());
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
    final initialCode = widget.initialGymCode;
    if (initialCode != null && initialCode.isNotEmpty) {
      final upper = initialCode.toUpperCase();
      _gymController.text = upper;
      for (var i = 0; i < _gymDigitControllers.length; i++) {
        _gymDigitControllers[i].text = i < upper.length ? upper[i] : '';
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.gymCodeReadOnly) return;
        _gymFocusNodes.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _gymController.dispose();
    for (final node in _gymFocusNodes) {
      node.dispose();
    }
    for (final controller in _gymDigitControllers) {
      controller.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLocked) return;
    if (!_formKey.currentState!.validate()) return;

    FocusManager.instance.primaryFocus?.unfocus();
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

      final expectedGymId = widget.expectedGymId;
      if (expectedGymId != null && expectedGymId.isNotEmpty) {
        if (validation.gymId != expectedGymId) {
          AnalyticsService.logGymCodeValidation(
            gymId: expectedGymId,
            status: 'error',
            reason: 'wrong_gym',
          );
          setState(() {
            _gymError = AppLocalizations.of(context)!.gymCodeInvalid;
          });
          return;
        }
      }

      AnalyticsService.logGymCodeValidation(
        gymId: validation.gymId,
        status: 'success',
      );

      AnalyticsService.logEvent(
        'gym_register_attempt',
        parameters: {'gym_id': validation.gymId},
      );

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
      final authProv = ref.read(authControllerProvider);
      final loc = AppLocalizations.of(context)!;
      final result = await authProv.register(email, password, gymCode);
      if (!mounted) return;

      if (!result.success || authProv.error != null) {
        AnalyticsService.logEvent(
          'gym_register_failed',
          parameters: {
            'gym_id': validation.gymId,
            if (authProv.error != null) 'reason': authProv.error!,
          },
        );
        final message = authProv.error ?? '${loc.errorPrefix}: unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AuthTheme.danger.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      AnalyticsService.logEvent(
        'gym_register_success',
        parameters: {'gym_id': validation.gymId},
      );

      if (result.missingMembership) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.missingMembershipError)));
      }

      final requiresGymSelection =
          result.requiresGymSelection ||
          result.gymContextStatus == GymContextStatus.missingSelection;

      if (requiresGymSelection) {
        Navigator.of(context).pushReplacementNamed(AppRouter.selectGym);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false,
          arguments: 1,
        );
      }
    } on GymCodeExpiredException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.expectedGymId ?? 'unknown',
        status: 'error',
        reason: 'expired',
      );
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = 'Code expired. Please get the current code from your gym.';
      });
      _handleFailedAttempt();
    } on GymCodeNotFoundException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.expectedGymId ?? 'unknown',
        status: 'error',
        reason: 'not_found',
      );
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = AppLocalizations.of(context)!.gymCodeInvalid;
      });
      _handleFailedAttempt();
    } on GymCodeInactiveException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.expectedGymId ?? 'unknown',
        status: 'error',
        reason: 'inactive',
      );
      if (!mounted) return;
      setState(() {
        _attempts++;
        _gymError = 'This code is no longer active. Please get a new code.';
      });
      _handleFailedAttempt();
    } on InvalidCodeFormatException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.expectedGymId ?? 'unknown',
        status: 'error',
        reason: 'invalid_format',
      );
      if (!mounted) return;
      setState(() {
        _gymError = 'Invalid code format. Code must be 6 characters.';
      });
    } catch (e) {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.expectedGymId ?? 'unknown',
        status: 'error',
        reason: 'unknown',
      );
      if (!mounted) return;
      setState(() {
        _gymError = 'Error validating code: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _handleGymCodeChange(String value) {
    final normalized = value.toUpperCase();
    if (_gymController.text != normalized) {
      _gymController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    if (_gymError != null) {
      setState(() => _gymError = null);
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
          backgroundColor: AuthTheme.danger.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.gymCodeHelpLabel,
            textColor: AuthTheme.textPrimary,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthLoading = ref.watch(
      authControllerProvider.select((auth) => auth.isLoading),
    );
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
            validator: (v) =>
                v != null && v.contains('@') ? null : loc.emailInvalid,
          ),
          const SizedBox(height: AuthTheme.spacingM),

          PremiumTextField(
            label: loc.passwordFieldLabel,
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v != null && v.length >= 6 ? null : loc.passwordTooShort,
          ),
          const SizedBox(height: AuthTheme.spacingM),

          _GymCodeOtpInput(
            label: loc.gymCodeFieldLabel,
            focusNodes: _gymFocusNodes,
            controllers: _gymDigitControllers,
            readOnly: widget.gymCodeReadOnly,
            errorText: _isLocked
                ? AppLocalizations.of(context)!.gymCodeLockedMessage
                : _gymError,
            onChanged: (value) => _handleGymCodeChange(value),
          ),

          const SizedBox(height: AuthTheme.spacingL),

          PremiumButton(
            text: _isLocked
                ? 'Locked (${(_lockDuration.inSeconds).toString()}s)'
                : loc.registerButton,
            isLoading: isAuthLoading || _isValidating,
            onPressed: (isAuthLoading || _isValidating || _isLocked)
                ? null
                : _submit,
          ),
        ],
      ),
    );
  }
}

class _GymCodeOtpInput extends StatelessWidget {
  const _GymCodeOtpInput({
    required this.label,
    required this.focusNodes,
    required this.controllers,
    required this.readOnly,
    required this.errorText,
    required this.onChanged,
  });

  final String label;
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final bool readOnly;
  final String? errorText;
  final ValueChanged<String> onChanged;
  static const _allowed = 'ABCDEFGHJKLMNPQRTUVWXY3468';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuthTheme.labelStyle.copyWith(color: AuthTheme.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              child: TextField(
                focusNode: focusNodes[index],
                controller: controllers[index],
                readOnly: readOnly,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: index == 5
                    ? TextInputAction.done
                    : TextInputAction.next,
                maxLength: 1,
                scrollPadding: const EdgeInsets.only(bottom: 180),
                style: AuthTheme.bodyStyle.copyWith(
                  color: AuthTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AuthTheme.surfaceRaised,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AuthTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AuthTheme.borderStrong,
                      width: 1.4,
                    ),
                  ),
                ),
                onChanged: (value) {
                  var upper = value.toUpperCase();
                  if (upper.length > 1) {
                    final filtered = upper
                        .split('')
                        .where((ch) => _allowed.contains(ch))
                        .toList();
                    for (var i = 0; i < controllers.length; i++) {
                      final digit = i < filtered.length ? filtered[i] : '';
                      controllers[i].value = TextEditingValue(
                        text: digit,
                        selection: TextSelection.collapsed(
                          offset: digit.isEmpty ? 0 : 1,
                        ),
                      );
                    }
                    onChanged(filtered.join());
                    if (filtered.length >= controllers.length) {
                      focusNodes.last.unfocus();
                    } else {
                      focusNodes[filtered.length].requestFocus();
                    }
                    return;
                  }
                  if (!_allowed.contains(upper) && upper.isNotEmpty) {
                    upper = '';
                  }
                  if (controllers[index].text != upper) {
                    controllers[index].value = TextEditingValue(
                      text: upper,
                      selection: TextSelection.collapsed(
                        offset: upper.isEmpty ? 0 : 1,
                      ),
                    );
                  }
                  final joined = controllers.map((c) => c.text).join();
                  onChanged(joined);
                  if (upper.isNotEmpty && index < 5) {
                    focusNodes[index + 1].requestFocus();
                  } else if (upper.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                },
                onSubmitted: (_) {
                  if (index < 5) {
                    focusNodes[index + 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(color: AuthTheme.danger, fontSize: 12),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            loc.gymCodeInvalid,
            style: TextStyle(
              color: AuthTheme.textMuted.withOpacity(0.65),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
