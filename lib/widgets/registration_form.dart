import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registrierung eines neuen Nutzers über Firebase Auth und Anlage eines Firestore-Dokuments.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({Key? key}) : super(key: key);

  @override
  RegistrationFormState createState() => RegistrationFormState();
}

class RegistrationFormState extends State<RegistrationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controller für Eingabefelder
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _membershipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _error = '';
  String _success = '';
  bool _isSubmitting = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Registriert einen neuen Benutzer und erstellt anschließend ein Dokument in Firestore.
  Future<void> _handleRegistration() async {
    print("=> Registrierung gestartet.");
    if (!_formKey.currentState!.validate()) {
      print("Formularvalidierung fehlgeschlagen.");
      return;
    }

    setState(() {
      _error = '';
      _success = '';
      _isSubmitting = true;
    });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String membershipNumber = _membershipController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmController.text;

    print("Eingegebene Daten: Name: $name, Email: $email, Mitgliedsnummer: $membershipNumber");

    if (password != confirmPassword) {
      setState(() {
        _error = 'Die Passwörter stimmen nicht überein.';
        _isSubmitting = false;
      });
      print("Fehler: Passwörter stimmen nicht überein.");
      return;
    }

    final int? memberNum = int.tryParse(membershipNumber);
    if (memberNum == null || memberNum < 1 || memberNum > 3000) {
      setState(() {
        _error = 'Die Mitgliedsnummer muss zwischen 0001 und 3000 liegen.';
        _isSubmitting = false;
      });
      print("Fehler: Ungültige Mitgliedsnummer ($membershipNumber).");
      return;
    }

    try {
      // Registrierung über Firebase Auth
      print("Firebase Auth: createUserWithEmailAndPassword wird aufgerufen...");
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Firebase Auth: User erstellt mit UID: ${userCredential.user!.uid}");

      // Firestore-Dokument erstellen
      print("Firestore: Schreibe Nutzerdokument in die 'users'-Collection...");
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'membership_number': membershipNumber,
        'current_streak': 0,
        'role': 'user', // Standardrolle
        'exp': 0,
        'exp_progress': 0,
        'division_number': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      print("Firestore: Schreibvorgang abgeschlossen.");

      // Direkt danach das neu angelegte Dokument abrufen zur Überprüfung:
      DocumentSnapshot newUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final dynamic newData = newUserDoc.data();
      print("DEBUG: Neues Nutzer-Dokument abgerufen: $newData");
      print("DEBUG: Typ des Nutzer-Dokuments: ${newData.runtimeType}");

      // Speichere wichtige Daten lokal in SharedPreferences
      print("SharedPreferences: Speichere Token und Nutzerdaten lokal...");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final idTokenResult = await userCredential.user!.getIdTokenResult();
      final String token = idTokenResult.token!;
      await prefs.setString('token', token);
      await prefs.setString('userId', userCredential.user!.uid);
      await prefs.setString('username', name);
      await prefs.setString('role', 'user');
      print("SharedPreferences: Daten gespeichert.");

      setState(() {
        _success = 'Registrierung erfolgreich!';
        _error = '';
      });

      // Navigation zur Startseite
      print("Navigation: Wechsle zur Startseite...");
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

      // Eingabefelder leeren
      _nameController.clear();
      _emailController.clear();
      _membershipController.clear();
      _passwordController.clear();
      _confirmController.clear();
      print("Registrierung abgeschlossen.");
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException bei der Registrierung: ${e.code} - ${e.message}");
      if (e.code == 'email-already-in-use') {
        setState(() {
          _error = 'Die E-Mail-Adresse wird bereits verwendet.';
        });
      } else {
        setState(() {
          _error = e.message ?? 'Registrierung fehlgeschlagen.';
        });
      }
    } catch (e) {
      print("Exception bei der Registrierung: $e");
      setState(() {
        _error = 'Ein Fehler ist aufgetreten.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
      print("=> Registrierung beendet.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Registrierung',
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bitte geben Sie Ihren Namen ein.' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-Mail'),
                keyboardType: TextInputType.emailAddress,
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
                controller: _membershipController,
                decoration: const InputDecoration(
                  labelText: 'Mitgliedsnummer',
                  hintText: 'z.B. 0001',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte geben Sie Ihre Mitgliedsnummer ein.';
                  }
                  final memberNum = int.tryParse(value.trim());
                  if (memberNum == null || memberNum < 1 || memberNum > 3000) {
                    return 'Die Mitgliedsnummer muss zwischen 0001 und 3000 liegen.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Passwort'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Bitte geben Sie ein Passwort ein.' : null,
              ),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: 'Passwort bestätigen'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte bestätigen Sie Ihr Passwort.';
                  }
                  if (value != _passwordController.text) {
                    return 'Die Passwörter stimmen nicht überein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleRegistration,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : Text('Registrieren', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _membershipController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
