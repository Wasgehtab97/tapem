import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);
  
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _error = '';
  String _success = '';
  bool _isSubmitting = false;

  /// Authentifiziert den Nutzer über Firebase Auth und lädt die zugehörigen Firestore-Daten.
  Future<void> _handleLogin() async {
    print("=> Login gestartet.");
    if (!_formKey.currentState!.validate()) {
      print("Login: Formularvalidierung fehlgeschlagen.");
      return;
    }
    
    setState(() {
      _error = '';
      _success = '';
      _isSubmitting = true;
    });
    
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    print("Login: Eingegebene Email: $email");
    
    try {
      print("Firebase Auth: signInWithEmailAndPassword wird aufgerufen...");
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Firebase Auth: User angemeldet mit UID: ${userCredential.user!.uid}");
      
      // Lade zusätzliche Nutzerdaten aus Firestore
      print("Firestore: Lade Nutzerdokument von UID: ${userCredential.user!.uid}");
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      final dynamic rawData = userDoc.data();
      print("DEBUG: Rohdaten aus Firestore: $rawData");
      print("DEBUG: Typ der Firestore-Daten: ${rawData.runtimeType}");
      
      final Map<String, dynamic>? data = rawData as Map<String, dynamic>?;

      if (data == null) {
        print("Fehler: Es wurden keine Daten im Nutzer-Dokument gefunden.");
        setState(() {
          _error = 'Keine Nutzerdaten gefunden.';
        });
      } else {
        print("Firestore: Nutzerdaten erfolgreich geladen: ${data.toString()}");
      }

      // Speichere Daten in SharedPreferences
      print("SharedPreferences: Speichere Nutzerdaten lokal...");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userCredential.user!.uid);
      await prefs.setString('username', data?['name'] ?? '');
      await prefs.setString('role', data?['role'] ?? 'user');
      print("SharedPreferences: Daten erfolgreich gespeichert.");
      
      setState(() {
        _success = 'Login erfolgreich!';
        _error = '';
      });
      
      print("Navigation: Wechsle zur Startseite...");
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      print("=> Login beendet.");
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException beim Login: ${e.code} - ${e.message}");
      setState(() {
        _error = e.message ?? 'Login fehlgeschlagen.';
        _success = '';
      });
    } catch (e) {
      print("Exception beim Login: $e");
      setState(() {
        _error = 'Ein Fehler ist aufgetreten.';
        _success = '';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
      print("=> Login-Prozess abgeschlossen.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Login',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_error.isNotEmpty)
          Text(
            _error,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        if (_success.isNotEmpty)
          Text(
            _success,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green),
          ),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-Mail'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte geben Sie eine E-Mail ein.';
                  }
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Bitte geben Sie eine gültige E-Mail-Adresse ein.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Passwort'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bitte geben Sie ein Passwort ein.' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleLogin,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : Text('Login', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
