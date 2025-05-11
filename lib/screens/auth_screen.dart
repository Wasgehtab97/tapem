// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/gym_logo.dart';

/// AuthScreen: Kombinierte Login- & Registrierungsseite mit Tab-Switch.
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AuthService _auth = AuthService();

  final _loginKey = GlobalKey<FormState>();
  final _regKey   = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPwd   = TextEditingController();
  final _regName    = TextEditingController();
  final _regEmail   = TextEditingController();
  final _regPwd     = TextEditingController();
  final _regGymCode = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPwd.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPwd.dispose();
    _regGymCode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.login(
        email: _loginEmail.text.trim(),
        password: _loginPwd.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_regKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.register(
        email: _regEmail.text.trim(),
        password: _regPwd.text,
        displayName: _regName.text.trim(),
        gymId: _regGymCode.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anmelden / Registrieren'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [ Tab(text: 'Login'), Tab(text: 'Registrieren') ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red)),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(theme),
                      _buildRegisterForm(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _loginKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GymLogo(height: 60),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginEmail,
              decoration: const InputDecoration(labelText: 'E-Mail'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'Bitte E-Mail eingeben' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginPwd,
              decoration: const InputDecoration(labelText: 'Passwort'),
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Bitte Passwort eingeben' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _handleLogin, child: const Text('Login')),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _regKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GymLogo(height: 60),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regName,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Bitte Name eingeben' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regEmail,
              decoration: const InputDecoration(labelText: 'E-Mail'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'Bitte E-Mail eingeben' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regPwd,
              decoration: const InputDecoration(labelText: 'Passwort'),
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Bitte Passwort eingeben' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regGymCode,
              decoration: const InputDecoration(labelText: 'Gym-Code (Invitation)'),
              validator: (v) => (v == null || v.isEmpty) ? 'Bitte Gym-Code eingeben' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _handleRegister, child: const Text('Registrieren')),
          ],
        ),
      ),
    );
  }
}
