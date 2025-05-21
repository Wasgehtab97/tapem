import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final authProv = context.read<AuthProvider>();

    // Mindestens 800 ms anzeigen
    await Future.delayed(const Duration(milliseconds: 800));

    // Warten, bis currentUser geladen ist
    while (authProv.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Weiterleiten
    if (authProv.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(
        AppRouter.home,
        arguments: 1,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.auth);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
