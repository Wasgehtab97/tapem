import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/functions_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tapem/l10n/app_localizations.dart';

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

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;
    if (bytes.length > 500 * 1024) {
      final loc = AppLocalizations.of(context)!;
      setState(() => _error = loc.brandingImageTooLarge);
      return;
    }
    setState(() {
      _logoBytes = bytes;
      _error = null;
    });
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final gymId = context.read<AuthProvider>().gymCode;
    if (gymId == null) {
      setState(() => _error = loc.invalidGymSelectionError);
      return;
    }
    final primary = _primaryCtrl.text.replaceAll('#', '');
    final accent = _accentCtrl.text.replaceAll('#', '');

    if (!_hexReg.hasMatch(primary) ||
        !_hexReg.hasMatch(accent) ||
        _logoBytes == null) {
      setState(() => _error = loc.brandingInvalidConfig);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final callable = FunctionsProvider.instance.httpsCallable('updateBranding');
    try {
      await callable.call(<String, dynamic>{
        'gymId': gymId,
        'logo': base64Encode(_logoBytes!),
        'primaryColor': primary,
        'accentColor': accent,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = '${loc.errorPrefix}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.adminDashboardBranding)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_logoBytes != null) Image.memory(_logoBytes!, height: 100),
            ElevatedButton(
              onPressed: _pickLogo,
              child: Text(loc.brandingPickLogo),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _primaryCtrl,
              decoration: InputDecoration(labelText: loc.brandingPrimaryColorLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accentCtrl,
              decoration: InputDecoration(labelText: loc.brandingAccentColorLabel),
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
                      : Text(loc.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
