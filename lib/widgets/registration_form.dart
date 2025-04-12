import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({Key? key}) : super(key: key);
  
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _membershipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  
  String _error = '';
  String _success = '';
  
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final membershipNumber = _membershipController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmController.text;
    
    if (password != confirmPassword) {
      setState(() {
        _error = 'Die Passwörter stimmen nicht überein.';
      });
      return;
    }
    
    final memberNumInt = int.tryParse(membershipNumber);
    if (memberNumInt == null || memberNumInt < 1 || memberNumInt > 3000) {
      setState(() {
        _error = 'Die Mitgliedsnummer muss zwischen 0001 und 3000 liegen.';
      });
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'membershipNumber': memberNumInt,
          'password': password,
        }),
      );
      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _success = result['message'] ?? 'Registrierung erfolgreich!';
          _error = '';
        });
        _nameController.clear();
        _emailController.clear();
        _membershipController.clear();
        _passwordController.clear();
        _confirmController.clear();
      } else {
        setState(() {
          _error = result['error'] ?? 'Registrierung fehlgeschlagen.';
          _success = '';
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Ein Fehler ist aufgetreten.';
        _success = '';
      });
      debugPrint('Registrierungsfehler: $error');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Registrierung',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_error.isNotEmpty)
          Text(_error,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red)),
        if (_success.isNotEmpty)
          Text(_success,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.green)),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte geben Sie Ihren Namen ein.';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie ein Passwort ein.';
                  }
                  return null;
                },
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
                onPressed: _handleRegistration,
                child: Text('Registrieren',
                    style: Theme.of(context).textTheme.bodyMedium),
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
