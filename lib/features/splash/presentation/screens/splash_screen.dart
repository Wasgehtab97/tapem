import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_router.dart';
import '../../../../bootstrap/providers.dart';
import '../../application/splash_flow.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minimumDisplay = Duration(milliseconds: 800);

  DateTime? _startedAt;
  String? _errorMessage;
  bool _isRetrying = false;
  bool _didNavigate = false;
  Timer? _navigationTimer;
  ProviderSubscription<AuthViewState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _authStateSubscription = ref.listenManual<AuthViewState>(
      authViewStateProvider,
      (previous, next) => _handleAuthState(next),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleAuthState(ref.read(authViewStateProvider));
    });
  }

  void _handleAuthState(AuthViewState state) {
    if (!mounted || _didNavigate) return;
    if (state.hasError && !state.isLoggedIn) {
      setState(() {
        _errorMessage = state.error;
      });
      return;
    }
    if (_errorMessage != null && (!state.hasError || state.isLoggedIn)) {
      setState(() {
        _errorMessage = null;
      });
    }
    final destination = resolveSplashDestination(state);
    if (destination == null || _didNavigate) {
      return;
    }
    _scheduleNavigation(destination);
  }

  void _scheduleNavigation(SplashDestination destination) {
    final startedAt = _startedAt;
    if (startedAt == null) {
      _navigate(destination);
      return;
    }
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minimumDisplay - elapsed;
    final delay = remaining.isNegative ? Duration.zero : remaining;
    _navigationTimer?.cancel();
    _navigationTimer = Timer(delay, () {
      if (mounted) {
        _navigate(destination);
      }
    });
  }

  void _navigate(SplashDestination destination) {
    if (_didNavigate || !mounted) return;
    _didNavigate = true;
    final routeName = switch (destination) {
      SplashDestination.auth => AppRouter.auth,
      SplashDestination.selectGym => AppRouter.selectGym,
      SplashDestination.home => AppRouter.home,
    };
    Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: destination == SplashDestination.home ? 1 : null,
    );
  }

  Future<void> _retryLoadUser() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });
    try {
      await ref.read(authControllerProvider).reloadCurrentUser();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _authStateSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Fehler beim Laden deines Accounts',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bitte versuche es erneut. Fehler: $_errorMessage',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isRetrying ? null : _retryLoadUser,
                    child: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
