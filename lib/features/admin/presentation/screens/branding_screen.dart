import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:tapem/core/providers/auth_provider.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({Key? key}) : super(key: key);

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  Uint8List? _logoBytes;
  final _primaryCtrl = TextEditingController();
  final _accentCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  final _hexReg = RegExp(r'^[0-9a-fA-F]{6}\$');

  // File selection via file_picker was removed to avoid an additional
  // dependency. Show a hint instead so the user can provide the logo data
  // manually if needed.
  Future<void> _pickLogo() async {
    setState(() => _error = 'Dateiauswahl nicht verfügbar');
  }

  Future<void> _save() async {
    final gymId = context.read<AuthProvider>().gymCode!;
    final primary = _primaryCtrl.text.replaceAll('#', '');
    final accent = _accentCtrl.text.replaceAll('#', '');

    if (!_hexReg.hasMatch(primary) ||
        !_hexReg.hasMatch(accent) ||
        _logoBytes == null) {
      setState(() => _error = 'Bitte gültige Farben und Logo wählen');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final callable = FirebaseFunctions.instance.httpsCallable('updateBranding');
    try {
      await callable.call(<String, dynamic>{
        'gymId': gymId,
        'logo': base64Encode(_logoBytes!),
        'primaryColor': primary,
        'accentColor': accent,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_logoBytes != null) Image.memory(_logoBytes!, height: 100),
            ElevatedButton(
              onPressed: _pickLogo,
              child: const Text('Logo auswählen'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _primaryCtrl,
              decoration: const InputDecoration(labelText: 'Primärfarbe (hex)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accentCtrl,
              decoration: const InputDecoration(labelText: 'Akzentfarbe (hex)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child:
                  _loading
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
