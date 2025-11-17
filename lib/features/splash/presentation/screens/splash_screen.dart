import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext({bool skipSplashDelay = false}) async {
    final authProv = context.read<AuthProvider>();

    // Mindestens 800 ms anzeigen
    if (!skipSplashDelay) {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Warten, bis currentUser geladen ist
    while (authProv.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    if (!mounted) return;

    final error = authProv.error;
    if (error != null && !authProv.isLoggedIn) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Weiterleiten
    if (authProv.isLoggedIn) {
      if (authProv.gymContextStatus == GymContextStatus.ready) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home, arguments: 1);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRouter.selectGym);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.auth);
    }
  }

  Future<void> _retryLoadUser() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });

    try {
      final authProv = context.read<AuthProvider>();
      await authProv.reloadCurrentUser();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }

    if (!mounted) return;
    await _navigateNext(skipSplashDelay: true);
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
