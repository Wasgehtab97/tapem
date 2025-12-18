// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/theme/brand_theme_preset.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/profile/presentation/widgets/change_username_sheet.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const SettingsScreen());
  }

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GlobalKey<FormState> _bodyMetricsFormKey = GlobalKey<FormState>();
  late final TextEditingController _bodyWeightCtrl;
  late final FocusNode _bodyWeightFocus;
  SettingsProvider? _settingsProvider;

  @override
  void initState() {
    super.initState();
    _bodyWeightCtrl = TextEditingController();
    _bodyWeightFocus = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = ref.read(settingsProvider);
    if (!identical(_settingsProvider, provider)) {
      _settingsProvider?.removeListener(_onSettingsChanged);
      _settingsProvider = provider;
      _settingsProvider?.addListener(_onSettingsChanged);
      _syncBodyMetricsFromSettings();
    }
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }
    _syncBodyMetricsFromSettings();
  }

  void _syncBodyMetricsFromSettings() {
    final settings = _settingsProvider;
    if (settings == null) {
      return;
    }
    final target = settings.bodyWeightKg;
    final formatted =
        target != null && target > 0 ? target.toStringAsFixed(1) : '';
    if (_bodyWeightCtrl.text != formatted) {
      _bodyWeightCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void dispose() {
    _settingsProvider?.removeListener(_onSettingsChanged);
    _bodyWeightCtrl.dispose();
    _bodyWeightFocus.dispose();
    super.dispose();
  }

  void _showLanguageDialog() {
    final appProv = ref.read(app.appProvider);
    final loc = AppLocalizations.of(context)!;
    final currentLocale = appProv.locale ?? Localizations.localeOf(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
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
            RadioListTile<Locale?>(
              title: Text(loc.settingsLanguageSystemDefault),
              value: null,
              groupValue: appProv.locale,
              onChanged: (_) {
                appProv.resetLocale();
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
    final authProv = ref.read(authControllerProvider);
    final loc = AppLocalizations.of(context)!;
    final current = authProv.showInLeaderboard ?? true;
    showDialog<void>(
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
                if (v == null) return;
                authProv.setShowInLeaderboard(v);
                authProv.setPublicProfile(v);
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: Text(loc.publicProfilePrivate),
              value: false,
              groupValue: current,
              onChanged: (v) {
                if (v == null) return;
                authProv.setShowInLeaderboard(v);
                authProv.setPublicProfile(v);
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

  void _toggleCoachRole() async {
    final authProv = ref.read(authControllerProvider);
    final loc = AppLocalizations.of(context)!;
    final isCoach = authProv.isCoach;
    final newValue = !isCoach;
    try {
      await authProv.setCoachEnabled(newValue);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Coaching-Rolle aktiviert – Coaching-Tab ist jetzt sichtbar.'
                : 'Coaching-Rolle deaktiviert.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.commonSaveError)),
      );
    }
  }

  void _showCoachingSettingsSheet() {
    final loc = AppLocalizations.of(context)!;
    final authProv = ref.read(authControllerProvider);
    final settingsProv = ref.read(settingsProvider);
    final isCoach = authProv.isCoach;
    final coachingProfileEnabled = settingsProv.coachingProfileEnabled;

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Coach Test-Option'),
              subtitle: const Text(
                'Aktiviert eine Coach-Rolle für diesen Account, '
                'um das Coaching-Feature vor dem Livegang zu testen.',
              ),
              trailing: Switch(
                value: isCoach,
                onChanged: (_) => _toggleCoachRole(),
              ),
              onTap: () => _toggleCoachRole(),
            ),
            ListTile(
              title: const Text('Coaching im Profil anzeigen'),
              subtitle: const Text(
                'Blendet auf der Profilseite den Coaching-Bereich '
                'und den Coaching-Button ein oder aus.',
              ),
              trailing: Switch(
                value: coachingProfileEnabled,
                onChanged: (v) async {
                  Navigator.pop(context);
                  try {
                    await settingsProv.setCoachingProfileEnabled(v);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v
                              ? 'Coaching-Bereich im Profil aktiviert.'
                              : 'Coaching-Bereich im Profil ausgeblendet.',
                        ),
                      ),
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.commonSaveError)),
                    );
                  }
                },
              ),
              onTap: () async {
                final newValue = !coachingProfileEnabled;
                Navigator.pop(context);
                try {
                  await settingsProv.setCoachingProfileEnabled(newValue);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newValue
                            ? 'Coaching-Bereich im Profil aktiviert.'
                            : 'Coaching-Bereich im Profil ausgeblendet.',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.commonSaveError)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatineSheet() {
    final loc = AppLocalizations.of(context)!;
    final settingsProv = ref.read(settingsProvider);
    final enabled = settingsProv.creatineEnabled;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(loc.settingsCreatineEnable),
              trailing: enabled ? const Icon(Icons.check) : null,
              onTap: () async {
                Navigator.pop(context);
                try {
                  await settingsProv.setCreatineEnabled(true);
                  elogUi('settings_set_creatine_enabled', {'enabled': true});
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.settingsCreatineSavedEnabled)),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.commonSaveError)),
                  );
                }
              },
            ),
            ListTile(
              title: Text(loc.settingsCreatineDisable),
              trailing: enabled ? null : const Icon(Icons.check),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await settingsProv.setCreatineEnabled(false);
                  elogUi('settings_set_creatine_enabled', {'enabled': false});
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.settingsCreatineSavedDisabled)),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.commonSaveError)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _themeOptionLabel(AppLocalizations loc, BrandThemeId id) {
    switch (id) {
      case BrandThemeId.mintTurquoise:
        return loc.settingsThemeMintTurquoise;
      case BrandThemeId.magentaViolet:
        return loc.settingsThemeMagentaViolet;
      case BrandThemeId.redOrange:
        return loc.settingsThemeRedOrange;
      case BrandThemeId.blackWhite:
        return loc.settingsThemeBlackWhite;
      case BrandThemeId.azureSapphire:
        return loc.settingsThemeAzureSapphire;
      case BrandThemeId.amberSunset:
        return loc.settingsThemeAmberSunset;
      case BrandThemeId.forestEmerald:
        return loc.settingsThemeForestEmerald;
      case BrandThemeId.royalPlum:
        return loc.settingsThemeRoyalPlum;
      case BrandThemeId.neonLime:
        return loc.settingsThemeNeonLime;
      case BrandThemeId.copperBronze:
        return loc.settingsThemeCopperBronze;
      case BrandThemeId.arcticSky:
        return loc.settingsThemeArcticSky;
      case BrandThemeId.emberInferno:
        return loc.settingsThemeEmberInferno;
      case BrandThemeId.cyberGrape:
        return loc.settingsThemeCyberGrape;
      case BrandThemeId.citrusPunch:
        return loc.settingsThemeCitrusPunch;
      case BrandThemeId.cyberpunkNeon:
        return loc.settingsThemeCyberpunkNeon;
      case BrandThemeId.animeBloom:
        return loc.settingsThemeAnimeBloom;
      case BrandThemeId.flameInferno:
        return loc.settingsThemeFlameInferno;
      case BrandThemeId.waterTribe:
        return loc.settingsThemeWaterTribe;
      case BrandThemeId.airNomads:
        return loc.settingsThemeAirNomads;
      case BrandThemeId.earthKingdom:
        return loc.settingsThemeEarthKingdom;
    }
  }

  String _currentThemeLabel(
    AppLocalizations loc,
    ThemePreferenceProvider themePref,
    String? gymId,
  ) {
    final override = themePref.override;
    if (override == null) {
      final manual = themePref.manualDefaultForGym(gymId);
      if (manual == null) {
        return loc.settingsThemeDefault;
      }
      return '${loc.settingsThemeDefault} · ${_themeOptionLabel(loc, manual)}';
    }
    return _themeOptionLabel(loc, override);
  }

  void _showThemeDialog() {
    final loc = AppLocalizations.of(context)!;
    final auth = ref.read(authControllerProvider);
    final themePref = ref.read(themePreferenceProvider);
    final gymId = auth.gymCode;
    final manualDefault = themePref.manualDefaultForGym(gymId);

    final availableIds = themePref.availableForGym(gymId);
    final additionalOptions = availableIds
        .where((id) => manualDefault == null || id != manualDefault)
        .toList();
    final selectedId = themePref.override;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        Widget buildThemeCard({
          required String label,
          required BrandThemePreset? preset,
          required bool isSelected,
          required VoidCallback onTap,
        }) {
          final gradient = preset != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [preset.gradientStart, preset.gradientEnd],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade800,
                    Colors.black,
                  ],
                );

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (preset?.gradientStart ?? Colors.white).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  if (isSelected)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: preset?.gradientEnd ?? Colors.black,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    child: Text(
                      loc.settingsThemeDialogTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: GridView(
                      controller: controller,
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      children: [
                        buildThemeCard(
                          label: manualDefault != null
                              ? '${loc.settingsThemeDefault} (${_themeOptionLabel(loc, manualDefault)})'
                              : loc.settingsThemeDefault,
                          preset: manualDefault != null ? BrandThemePresets.of(manualDefault) : null,
                          isSelected: selectedId == null,
                          onTap: () => _onThemeSelected(sheetContext, null),
                        ),
                        for (final id in additionalOptions)
                          buildThemeCard(
                            label: _themeOptionLabel(loc, id),
                            preset: BrandThemePresets.of(id),
                            isSelected: selectedId == id,
                            onTap: () => _onThemeSelected(sheetContext, id),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onThemeSelected(
    BuildContext dialogContext,
    BrandThemeId? id,
  ) async {
    Navigator.pop(dialogContext);
    try {
      await ref.read(themePreferenceProvider).setTheme(id);
    } catch (_) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.settingsThemeSaveError)),
      );
    }
  }

  String? _genderLabel(AppLocalizations loc, String? gender) {
    switch (gender) {
      case 'm':
        return loc.settingsGenderMale;
      case 'w':
        return loc.settingsGenderFemale;
      case 'divers':
        return loc.settingsGenderDiverse;
    }
    return null;
  }

  String _bodyMetricsSummary(AppLocalizations loc) {
    final settings = ref.read(settingsProvider);
    final labels = <String>[];
    final genderLabel = _genderLabel(loc, settings.gender);
    if (genderLabel != null) {
      labels.add(genderLabel);
    }
    final weight = settings.bodyWeightKg;
    if (weight != null && weight > 0) {
      labels.add(loc.settingsBodyWeightSummary(weight.toStringAsFixed(1)));
    }
    if (labels.isEmpty) {
      return loc.settingsBodyMetricsSummaryEmpty;
    }
    return labels.join(' · ');
  }

  Future<void> _showBodyMetricsSheet() async {
    final loc = AppLocalizations.of(context)!;
    final SettingsProvider settingsProv =
        _settingsProvider ?? ref.read(settingsProvider);
    _syncBodyMetricsFromSettings();
    _bodyMetricsFormKey.currentState?.reset();

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        String? selectedGender = settingsProv.gender;
        return StatefulBuilder(
          builder: (formContext, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                      AppSpacing.lg,
                ),
                child: Form(
                  key: _bodyMetricsFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loc.settingsBodyMetricsDialogTitle,
                          style: Theme.of(formContext).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String?>(
                          value: selectedGender,
                          decoration: InputDecoration(
                            labelText: loc.settingsGenderLabel,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(loc.settingsGenderNone),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'w',
                              child: Text(loc.settingsGenderFemale),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'm',
                              child: Text(loc.settingsGenderMale),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'divers',
                              child: Text(loc.settingsGenderDiverse),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const ValueKey('bodyWeightField'),
                          controller: _bodyWeightCtrl,
                          focusNode: _bodyWeightFocus,
                          decoration: InputDecoration(
                            labelText: loc.settingsBodyWeightLabel,
                            hintText: loc.settingsBodyWeightHint,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          validator: (value) {
                            final raw = value?.trim() ?? '';
                            if (raw.isEmpty) {
                              return null;
                            }
                            final normalized = raw.replaceAll(',', '.');
                            final parsed = double.tryParse(normalized);
                            if (parsed == null || parsed <= 0 || parsed > 500) {
                              return loc.settingsBodyWeightError;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            _handleBodyMetricsSubmit(
                                sheetContext, selectedGender, loc);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () => _handleBodyMetricsSubmit(
                            sheetContext,
                            selectedGender,
                            loc,
                          ),
                          child: Text(loc.commonOk),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      await settingsProv.updateProfile(
        gender: result['gender'] as String?,
        bodyWeightKg: result['bodyWeight'] as double?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.settingsBodyMetricsSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.settingsBodyMetricsSaveError)),
      );
    }
  }

  void _handleBodyMetricsSubmit(
    BuildContext sheetContext,
    String? selectedGender,
    AppLocalizations loc,
  ) {
    final form = _bodyMetricsFormKey.currentState;
    if (form == null) {
      return;
    }
    if (!form.validate()) {
      _bodyWeightFocus.requestFocus();
      return;
    }
    final raw = _bodyWeightCtrl.text.trim();
    final normalized = raw.replaceAll(',', '.');
    final parsed = normalized.isEmpty ? null : double.parse(normalized);
    Navigator.of(sheetContext).pop({
      'gender': selectedGender,
      'bodyWeight': parsed,
    });
  }

  void _showLegalPlaceholder(String label) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.settingsLegalPlaceholder(label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final settings = ref.watch(settingsProvider);
    final themePref = ref.watch(themePreferenceProvider);
    final appProv = ref.watch(app.appProvider);
    final locale = appProv.locale ?? Localizations.localeOf(context);
    final languageLabel = _languageLabel(loc, appProv.locale, locale);
    final themeLabel = _currentThemeLabel(loc, themePref, auth.gymCode);
    final bodySummary = _bodyMetricsSummary(loc);
    final creatineStatus =
        settings.creatineEnabled ? loc.settingsCreatineEnabled : loc.settingsCreatineDisabled;
    final privacyLabel =
        (auth.publicProfile ?? auth.showInLeaderboard ?? true)
            ? loc.publicProfilePublic
            : loc.publicProfilePrivate;
    final username = auth.userName ?? loc.genericUser;

    final localeName = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsScreenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SettingsSection(
            title: loc.settingsSectionPersonalization,
            children: [
              _PremiumSettingsTile(
                icon: Icons.language,
                title: loc.settingsOptionLanguage,
                subtitle: languageLabel,
                onTap: _showLanguageDialog,
              ),
              _PremiumSettingsTile(
                icon: Icons.palette,
                title: loc.settingsOptionTheme,
                subtitle: themeLabel,
                onTap: _showThemeDialog,
              ),
            ],
          ),
          _SettingsSection(
            title: loc.settingsSectionHealthTracking,
            children: [
              _PremiumSettingsTile(
                icon: Icons.monitor_weight,
                title: loc.settingsBodyMetrics,
                subtitle: bodySummary,
                onTap: _showBodyMetricsSheet,
              ),
              _PremiumSettingsTile(
                icon: Icons.health_and_safety,
                title: loc.settingsCreatineTracker,
                subtitle: creatineStatus,
                onTap: () {
                  elogUi('settings_open_creatine', {});
                  _showCreatineSheet();
                },
              ),
            ],
          ),
          _SettingsSection(
            title: loc.settingsSectionVisibilityAccount,
            children: [
              _PremiumSettingsTile(
                icon: Icons.school,
                title: 'Coaching',
                subtitle:
                    'Coach-Test-Option und Sichtbarkeit des Coaching-Bereichs.',
                onTap: _showCoachingSettingsSheet,
              ),
              _PremiumSettingsTile(
                icon: Icons.visibility,
                title: loc.settingsOptionPublicProfile,
                subtitle: privacyLabel,
                onTap: _showPrivacyDialog,
              ),
              _PremiumSettingsTile(
                icon: Icons.person,
                title: loc.settingsOptionChangeUsername,
                subtitle: loc.settingsUsernameCurrent(username),
                onTap: () => showChangeUsernameSheet(context),
              ),
            ],
          ),
          _SettingsSection(
            title: loc.settingsSectionLegal,
            children: [
              _PremiumSettingsTile(
                icon: Icons.gavel,
                title: loc.settingsLegalImprint,
                subtitle: loc.settingsLegalPlaceholderDescription,
                onTap: () => _showLegalPlaceholder(loc.settingsLegalImprint),
              ),
              _PremiumSettingsTile(
                icon: Icons.privacy_tip,
                title: loc.settingsLegalPrivacy,
                subtitle: loc.settingsLegalPlaceholderDescription,
                onTap: () => _showLegalPlaceholder(loc.settingsLegalPrivacy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            DateFormat.yMMMMd(localeName).format(DateTime.now()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _languageLabel(
    AppLocalizations loc,
    Locale? selected,
    Locale fallback,
  ) {
    final locale = selected ?? fallback;
    switch (locale.languageCode) {
      case 'de':
        return loc.germanLanguage;
      case 'en':
        return loc.englishLanguage;
      default:
        return loc.settingsLanguageSystemDefault;
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children.map((child) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: child,
              )),
        ],
      ),
    );
  }
}

class _PremiumSettingsTile extends StatelessWidget {
  const _PremiumSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brandColor.withOpacity(0.08),
                  brandColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: brandColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: brandColor.withOpacity(0.8),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
