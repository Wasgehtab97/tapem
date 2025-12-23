import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/features/auth/presentation/screens/gym_register_method_screen.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_button.dart';
import 'package:tapem/features/auth/presentation/widgets/registration_form.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_nfc_token.dart';
import 'package:tapem/features/nfc/data/nfc_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymRegisterScreen extends ConsumerStatefulWidget {
  const GymRegisterScreen({super.key, required this.args});

  final GymRegisterArgs args;

  @override
  ConsumerState<GymRegisterScreen> createState() => _GymRegisterScreenState();
}

class _GymRegisterScreenState extends ConsumerState<GymRegisterScreen> {
  StreamSubscription<String>? _nfcSub;
  bool _isScanning = false;
  String? _scanError;
  String? _prefilledCode;

  bool get _isNfc => widget.args.method == GymRegisterMethod.nfc;

  @override
  void initState() {
    super.initState();
    _prefilledCode = widget.args.prefilledGymCode;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(StorageKeys.preAuthGymId, widget.args.gymId);
    });
    if (_isNfc && (_prefilledCode == null || _prefilledCode!.isEmpty)) {
      _startNfcScan();
    }
  }

  @override
  void dispose() {
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
      gymId: widget.args.gymId,
      flow: 'register',
      status: 'started',
    );
    final available = await NfcManager.instance.isAvailable();
    if (!mounted) return;
    if (!available) {
      await AnalyticsService.logGymNfcScan(
        gymId: widget.args.gymId,
        flow: 'register',
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
          gymId: widget.args.gymId,
          flow: 'register',
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
        gymId: widget.args.gymId,
        flow: 'register',
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
        gymId: widget.args.gymId,
        token: token,
      );
      if (!mounted) return;
      setState(() {
        _prefilledCode = gymCode;
        _isScanning = false;
        _scanError = null;
      });
      AnalyticsService.logGymNfcScan(
        gymId: widget.args.gymId,
        flow: 'register',
        status: 'success',
      );
      _nfcSub?.cancel();
    } on GymNfcTokenInactiveException {
      AnalyticsService.logGymNfcScan(
        gymId: widget.args.gymId,
        flow: 'register',
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
        gymId: widget.args.gymId,
        flow: 'register',
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
        gymId: widget.args.gymId,
        flow: 'register',
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
        gymId: widget.args.gymId,
        flow: 'register',
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymAsync = ref.watch(gymByIdProvider(widget.args.gymId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: gymAsync.when(
          data: (gym) {
            final showScan = _isNfc && (_prefilledCode == null || _prefilledCode!.isEmpty);
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
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                      AppRouter.gymRegisterMethod,
                      arguments: widget.args.gymId,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.gymRegisterTitle(gym.name),
                  textAlign: TextAlign.center,
                  style: AuthTheme.headingStyle,
                ),
                if (_isNfc) ...[
                  const SizedBox(height: AuthTheme.spacingS),
                  Text(
                    loc.gymNfcHint,
                    textAlign: TextAlign.center,
                    style: AuthTheme.bodyStyle.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: AuthTheme.spacingL),
                if (showScan)
                  GlassCard(
                    child: Column(
                      children: [
                        Text(
                          loc.nfcScanTitle,
                          style: AuthTheme.headingStyle.copyWith(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AuthTheme.spacingS),
                        Text(
                          loc.nfcScanSubtitle,
                          textAlign: TextAlign.center,
                          style: AuthTheme.bodyStyle.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        if (_scanError != null) ...[
                          const SizedBox(height: AuthTheme.spacingS),
                          Text(
                            _scanError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF8A80),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: AuthTheme.spacingL),
                        PremiumButton(
                          text: _isScanning ? loc.nfcScanWaiting : loc.nfcScanRetry,
                          isLoading: _isScanning,
                          onPressed: _isScanning ? null : _startNfcScan,
                        ),
                        const SizedBox(height: AuthTheme.spacingS),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(
                            AppRouter.gymRegisterMethod,
                            arguments: widget.args.gymId,
                          ),
                          child: Text(
                            loc.nfcScanManual,
                            style: AuthTheme.labelStyle.copyWith(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GlassCard(
                    child: RegistrationForm(
                      initialGymCode: _prefilledCode,
                      gymCodeReadOnly: _isNfc && _prefilledCode != null,
                      expectedGymId: widget.args.gymId,
                      gymValidator: widget.args.gymValidator,
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
