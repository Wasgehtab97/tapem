// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/tenant/tenant_service.dart';
import '../services/auth_service.dart';

/// SplashScreen lädt GymConfig und leitet je nach Auth-Status weiter.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoLoadSavedGym();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Lädt automatisch, wenn eine Gym-ID in SharedPreferences steht.
  Future<void> _autoLoadSavedGym() async {
    final prefs    = await SharedPreferences.getInstance();
    final savedGym = prefs.getString(TenantService.gymIdKey);
    if (savedGym?.isNotEmpty ?? false) {
      await _processGymCode(savedGym!);
    }
  }

  /// Gemeinsame Logik: Tenant initialisieren und Navigation.
  Future<void> _processGymCode(String gymId) async {
    setState(() => _isLoading = true);

    try {
      await TenantService().init(gymId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TenantService.gymIdKey, gymId);

      final auth      = AuthService();
      final nextRoute = auth.isLoggedIn ? '/home' : '/auth';

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, nextRoute);
    } catch (e, st) {
      debugPrint('Fehler beim Laden der Gym-Config: $e\n$st');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ungültiger Gym-Code: "$gymId"')),
      );
    }
  }

  /// Button-Handler
  void _onLoadPressed() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Gym-Code eingeben.')),
      );
      return;
    }
    _processGymCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FlutterLogo(size: 80),
                    const SizedBox(height: 24),
                    Text(
                      'Tap’em Gym öffnen',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Gym-Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _onLoadPressed,
                      child: const Text('Laden'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
