import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_nfc_token.dart';
import 'package:tapem/features/nfc/data/nfc_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymJoinScreen extends ConsumerStatefulWidget {
  const GymJoinScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymJoinScreen> createState() => _GymJoinScreenState();
}

class _GymJoinScreenState extends ConsumerState<GymJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late final ValidateGymCode _validateGymCode;
  String? _error;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _scanError;
  StreamSubscription<String>? _nfcSub;

  @override
  void initState() {
    super.initState();
    _validateGymCode = ValidateGymCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nfcSub?.cancel();
    super.dispose();
  }

  Future<void> _startNfcScan() async {
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _scanError = null;
    });
    await AnalyticsService.logGymNfcScan(
      gymId: widget.gymId,
      flow: 'join',
      status: 'started',
    );
    final available = await NfcManager.instance.isAvailable();
    if (!mounted) return;
    if (!available) {
      await AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'error',
        reason: 'nfc_unavailable',
      );
      setState(() {
        _isScanning = false;
        _scanError = AppLocalizations.of(context)!.nfcUnavailable;
      });
      return;
    }
    final reader = ReadNfcCode(NfcService());
    _nfcSub?.cancel();
    _nfcSub = reader.execute().listen((code) {
      if (!mounted) return;
      final normalized = code.trim().toUpperCase();
      if (normalized.isEmpty) {
        AnalyticsService.logGymNfcScan(
          gymId: widget.gymId,
          flow: 'join',
          status: 'error',
          reason: 'empty_code',
        );
        setState(() {
          _isScanning = false;
          _scanError = AppLocalizations.of(context)!.nfcInvalidCode;
        });
        return;
      }
      _resolveNfcToken(normalized);
    }, onError: (_) {
      AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'error',
        reason: 'scan_failed',
      );
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = AppLocalizations.of(context)!.nfcScanFailed;
      });
    });
  }

  Future<void> _resolveNfcToken(String token) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final gymCode = await ValidateGymNfcToken().execute(
        gymId: widget.gymId,
        token: token,
      );
      if (!mounted) return;
      _codeController.value = TextEditingValue(
        text: gymCode,
        selection: TextSelection.collapsed(offset: gymCode.length),
      );
      setState(() {
        _isScanning = false;
        _scanError = null;
      });
      AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'success',
      );
      _nfcSub?.cancel();
    } on GymNfcTokenInactiveException {
      AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'error',
        reason: 'token_inactive',
      );
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = loc.nfcTokenInactive;
      });
    } on GymNfcTokenNotFoundException {
      AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'error',
        reason: 'token_not_found',
      );
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = loc.nfcInvalidCode;
      });
    } on GymNfcTokenInvalidException {
      AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'error',
        reason: 'token_invalid',
      );
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = loc.nfcInvalidCode;
      });
    } catch (_) {
      AnalyticsService.logGymNfcScan(
        gymId: widget.gymId,
        flow: 'join',
        status: 'error',
        reason: 'unknown',
      );
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = loc.nfcScanFailed;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();
      final validation = await _validateGymCode.execute(code);
      if (!mounted) return;
      if (validation.gymId != widget.gymId) {
        AnalyticsService.logGymCodeValidation(
          gymId: widget.gymId,
          status: 'error',
          reason: 'wrong_gym',
        );
        setState(() {
          _error = AppLocalizations.of(context)!.gymCodeInvalid;
        });
        return;
      }

      final auth = ref.read(authControllerProvider);
      final result = await auth.addGymMembership(widget.gymId);
      if (!mounted) return;
      if (result.success) {
        AnalyticsService.logGymCodeValidation(
          gymId: widget.gymId,
          status: 'success',
        );
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.remove(StorageKeys.preAuthGymId);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRouter.home,
          arguments: 1,
        );
        return;
      }
      final loc = AppLocalizations.of(context)!;
      final message = result.errorCode ?? loc.membershipSyncError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on GymCodeNotFoundException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.gymId,
        status: 'error',
        reason: 'not_found',
      );
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.gymCodeInvalid;
      });
    } on GymCodeExpiredException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.gymId,
        status: 'error',
        reason: 'expired',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Code expired. Please get the current code from your gym.';
      });
    } on GymCodeInactiveException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.gymId,
        status: 'error',
        reason: 'inactive',
      );
      if (!mounted) return;
      setState(() {
        _error = 'This code is no longer active. Please get a new code.';
      });
    } on InvalidCodeFormatException {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.gymId,
        status: 'error',
        reason: 'invalid_format',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Invalid code format. Code must be 6 characters.';
      });
    } catch (e) {
      AnalyticsService.logGymCodeValidation(
        gymId: widget.gymId,
        status: 'error',
        reason: 'unknown',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Error validating code: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymAsync = ref.watch(gymByIdProvider(widget.gymId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: gymAsync.when(
          data: (gym) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                const SizedBox(height: 16),
                Center(
                  child: Hero(
                    tag: 'gym-logo-${gym.id}',
                    child: gym.logoUrl != null
                        ? CircleAvatar(
                            radius: 34,
                            backgroundImage: NetworkImage(gym.logoUrl!),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          )
                        : const CircleAvatar(
                            radius: 34,
                            child: Icon(Icons.fitness_center_outlined),
                          ),
                  ),
                ),
                const SizedBox(height: AuthTheme.spacingS),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      await prefs.remove(StorageKeys.preAuthGymId);
                      if (!mounted) return;
                      Navigator.of(context).pushReplacementNamed(
                        AppRouter.gymAccess,
                        arguments: widget.gymId,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.gymJoinTitle(gym.name),
                  textAlign: TextAlign.center,
                  style: AuthTheme.headingStyle,
                ),
                const SizedBox(height: AuthTheme.spacingS),
                Text(
                  loc.gymJoinSubtitle,
                  textAlign: TextAlign.center,
                  style: AuthTheme.bodyStyle.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
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
                          label: loc.gymCodeFieldLabel,
                          controller: _codeController,
                          prefixIcon: Icons.fitness_center_outlined,
                          textInputAction: TextInputAction.done,
                          onChanged: (val) {
                            final upper = val.toUpperCase();
                            if (val != upper) {
                              _codeController.value =
                                  _codeController.value.copyWith(
                                text: upper,
                                selection: TextSelection.collapsed(
                                  offset: upper.length,
                                ),
                              );
                            }
                          },
                          validator: (v) {
                            if (v == null || v.length != 6) {
                              return loc.gymCodeInvalid;
                            }
                            return _error;
                          },
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFFF8A80),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (_scanError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              _scanError!,
                              style: const TextStyle(
                                color: Color(0xFFFF8A80),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: AuthTheme.spacingS),
                        TextButton(
                          onPressed: _isScanning ? null : _startNfcScan,
                          child: Text(
                            _isScanning ? loc.nfcScanWaiting : loc.nfcScanTitle,
                            style: AuthTheme.labelStyle.copyWith(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: AuthTheme.spacingL),
                        PremiumButton(
                          text: loc.gymJoinCta,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                loc.authErrorGeneric(error),
                textAlign: TextAlign.center,
                style: AuthTheme.bodyStyle.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
