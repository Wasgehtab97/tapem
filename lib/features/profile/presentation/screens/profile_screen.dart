// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/calendar.dart';
import '../widgets/calendar_popup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadTrainingDates(context);
    });
  }

  void _showLanguageDialog() {
    final appProv = context.read<app.AppProvider>();
    final loc = AppLocalizations.of(context)!;
    final currentLocale = appProv.locale ?? Localizations.localeOf(context);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(loc.languageDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale>(
                  title: Text(loc.germanLanguage),
                  value: const Locale('de'),
                  groupValue: currentLocale,
                  onChanged: (l) {
                    appProv.setLocale(l!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<Locale>(
                  title: Text(loc.englishLanguage),
                  value: const Locale('en'),
                  groupValue: currentLocale,
                  onChanged: (l) {
                    appProv.setLocale(l!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancelButton),
              ),
            ],
          ),
    );
  }

  void _showPrivacyDialog() {
    final authProv = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context)!;
    final current = authProv.showInLeaderboard ?? true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.publicProfileDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: Text(loc.publicProfilePublic),
              value: true,
              groupValue: current,
              onChanged: (v) {
                authProv.setShowInLeaderboard(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: Text(loc.publicProfilePrivate),
              value: false,
              groupValue: current,
              onChanged: (v) {
                authProv.setShowInLeaderboard(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelButton),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(loc.settingsDialogTitle),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showLanguageDialog();
            },
            child: Text(loc.settingsOptionLanguage),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showPrivacyDialog();
            },
            child: Text(loc.settingsOptionPublicProfile),
          ),
        ],
      ),
    );
  }

  void _openCalendarPopup(List<String> trainingDates) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CalendarPopup(
            trainingDates: trainingDates,
            initialYear: DateTime.now().year,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
        actions: [
          const NfcScanButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.settingsIconTooltip,
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body:
          prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.error != null
              ? Center(child: Text('Fehler: ${prov.error}'))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Trainingstage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openCalendarPopup(prov.trainingDates),
                        child: Calendar(
                          trainingDates: prov.trainingDates,
                          showNavigation: false,
                          year: DateTime.now().year,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
