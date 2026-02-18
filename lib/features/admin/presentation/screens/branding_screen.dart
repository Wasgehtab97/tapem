import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:file_picker/file_picker.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/admin/data/services/branding_admin_service.dart';

import 'package:tapem/core/providers/auth_providers.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key, this.brandingService, this.firestore});

  final BrandingAdminService? brandingService;
  final FirebaseFirestore? firestore;

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  String? _logoFileName;
  final _primaryCtrl = TextEditingController();
  final _accentCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  late final BrandingAdminService _brandingService;
  bool _loading = false;
  String? _error;

  final _hexReg = RegExp(r'^[0-9a-fA-F]{6}\$');

  @override
  void initState() {
    super.initState();
    _brandingService =
        widget.brandingService ??
        BrandingAdminService(firestore: widget.firestore);
  }

  @override
  void dispose() {
    _primaryCtrl.dispose();
    _accentCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    setState(() {
      _logoFileName = result.files.single.name;
      _error = null;
    });
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final auth = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authControllerProvider);
    final gymId = auth.gymCode;
    if (gymId == null) {
      setState(() => _error = loc.invalidGymSelectionError);
      return;
    }
    final primary = _primaryCtrl.text.replaceAll('#', '');
    final accent = _accentCtrl.text.replaceAll('#', '');
    final logoUrl = _logoUrlCtrl.text.trim();

    if (!_hexReg.hasMatch(primary) || !_hexReg.hasMatch(accent)) {
      setState(() => _error = loc.brandingInvalidConfig);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _brandingService.saveBranding(
        BrandingSaveInput(
          gymId: gymId,
          actorUid: auth.userId ?? '',
          primaryHex: primary,
          accentHex: accent,
          logoUrl: logoUrl,
        ),
      );
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
            ElevatedButton(
              onPressed: _pickLogo,
              child: Text(loc.brandingPickLogo),
            ),
            if (_logoFileName != null) ...[
              const SizedBox(height: 8),
              Text(loc.brandingSelectedFile(_logoFileName!)),
              const SizedBox(height: 8),
              Text(loc.brandingLogoUrlHint),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _primaryCtrl,
              decoration: InputDecoration(
                labelText: loc.brandingPrimaryColorLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accentCtrl,
              decoration: InputDecoration(
                labelText: loc.brandingAccentColorLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _logoUrlCtrl,
              decoration: InputDecoration(
                labelText: loc.brandingLogoUrlLabel,
                hintText: loc.brandingLogoUrlPlaceholder,
              ),
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
              child: _loading
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
