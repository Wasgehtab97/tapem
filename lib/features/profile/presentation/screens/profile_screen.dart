// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
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
    final currentLocale = appProv.locale ?? Localizations.localeOf(context);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sprache wählen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale>(
                  title: const Text('Deutsch'),
                  value: const Locale('de'),
                  groupValue: currentLocale,
                  onChanged: (l) {
                    appProv.setLocale(l!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<Locale>(
                  title: const Text('English'),
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
                child: const Text('Abbrechen'),
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
        title: const Text('Profil'),
        actions: [
          const NfcScanButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Sprache',
            onPressed: _showLanguageDialog,
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
