// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/features/friends/providers/friend_alerts_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/brand_theme_preset.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/presentation/widgets/daily_xp_card.dart';
import '../widgets/daily_xp_avatar.dart';
import '../widgets/calendar.dart';
import '../widgets/calendar_popup.dart';
import '../../../survey/presentation/screens/survey_vote_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friends_home_screen.dart';
import '../widgets/change_username_sheet.dart';
import 'package:tapem/app_router.dart';
import 'profile_stats_screen.dart';

const bool enableFriends = true;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _bodyMetricsFormKey = GlobalKey<FormState>();
  late final TextEditingController _bodyWeightCtrl;
  late final FocusNode _bodyWeightFocus;
  SettingsProvider? _settingsProvider;

  @override
  void initState() {
    super.initState();
    _bodyWeightCtrl = TextEditingController();
    _bodyWeightFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadTrainingDates(context);
      final uid = context.read<AuthProvider>().userId;
      if (uid != null) {
        context.read<FriendAlertsProvider>().listen(uid);
        context.read<SettingsProvider>().load(uid);
        final gymId = context.read<AuthProvider>().gymCode ?? '';
        context.read<XpProvider>().watchStatsDailyXp(gymId, uid);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SettingsProvider>();
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
      builder:
          (_) => AlertDialog(
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

  void _showInventorySheet(AuthProvider auth) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final normalized = AvatarAssets.normalizeKey(
          auth.avatarKey,
          currentGymId: auth.gymCode,
        );
        return AvatarPicker(
          currentKey: normalized,
          onSelect: (key) async {
            Navigator.pop(context);
            try {
              await auth.setAvatarKey(key);
            } catch (_) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.commonSaveError)),
              );
            }
          },
        );
      },
    );
  }

  void _showProfileXpSheet(AuthProvider auth) {
    final xpProv = context.read<XpProvider>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final locale = Localizations.localeOf(sheetContext).toString();
        final formatter = NumberFormat.decimalPattern(locale);
        final profile = PublicProfile(
          uid: auth.userId ?? '',
          username: auth.userName ?? '',
          avatarKey: auth.avatarKey,
          primaryGymCode: auth.gymCode,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: DailyXpCard(
              profile: profile,
              level: xpProv.dailyLevel,
              xpInLevel: xpProv.dailyLevelXp,
              totalXp: xpProv.statsDailyXp,
              numberFormat: formatter,
              xpPerLevel: LevelService.xpPerLevel,
              maxLevel: LevelService.maxLevel,
              margin: EdgeInsets.zero,
              onAvatarTap: () {
                Navigator.pop(sheetContext);
                _showInventorySheet(auth);
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreatineSheet() {
    final loc = AppLocalizations.of(context)!;
    final settingsProv = context.read<SettingsProvider>();
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.settingsCreatineSavedEnabled)),
                  );
                } catch (_) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.settingsCreatineSavedDisabled)),
                  );
                } catch (_) {
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
    }
  }

  String _currentThemeLabel(
    AppLocalizations loc,
    ThemePreferenceProvider themePref,
    String? gymId,
  ) {
    final override = themePref.override;
    if (override == null) {
      return loc.settingsThemeDefault;
    }
    return _themeOptionLabel(loc, override);
  }

  void _showThemeDialog() {
    final loc = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final themePref = context.read<ThemePreferenceProvider>();
    final gymId = auth.gymCode;
    final manualDefault = themePref.manualDefaultForGym(gymId);
    final additionalOptions = themePref
        .availableForGym(gymId)
        .where((id) => manualDefault == null || id != manualDefault)
        .toList();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final selected =
            dialogContext.watch<ThemePreferenceProvider>().override;
        return SimpleDialog(
          title: Text(loc.settingsThemeDialogTitle),
          children: [
            RadioListTile<BrandThemeId?>(
              value: null,
              groupValue: selected,
              onChanged: (_) => _onThemeSelected(dialogContext, null),
              title: Text(loc.settingsThemeDefault),
              subtitle: manualDefault != null
                  ? Text(_themeOptionLabel(loc, manualDefault))
                  : null,
            ),
            for (final option in additionalOptions)
              RadioListTile<BrandThemeId?>(
                value: option,
                groupValue: selected,
                onChanged: (_) => _onThemeSelected(dialogContext, option),
                title: Text(_themeOptionLabel(loc, option)),
              ),
          ],
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
      await context.read<ThemePreferenceProvider>().setTheme(id);
    } catch (_) {
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
    final settings = context.read<SettingsProvider>();
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
    final settingsProv = _settingsProvider ?? context.read<SettingsProvider>();
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
                  bottom:
                      MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
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
                          decoration:
                              InputDecoration(labelText: loc.settingsGenderLabel),
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
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator: (value) {
                            final raw = value?.trim();
                            if (raw == null || raw.isEmpty) {
                              return null;
                            }
                            final normalized = raw.replaceAll(',', '.');
                            final parsed = double.tryParse(normalized);
                            if (parsed == null || parsed <= 0 || parsed < 30 || parsed > 400) {
                              return loc.settingsBodyWeightError;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            _handleBodyMetricsSubmit(
                              sheetContext,
                              selectedGender,
                              loc,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: Text(loc.commonCancel),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            FilledButton(
                              onPressed: () => _handleBodyMetricsSubmit(
                                sheetContext,
                                selectedGender,
                                loc,
                              ),
                              child: Text(loc.commonSave),
                            ),
                          ],
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

    final newGender = result['gender'] as String?;
    final newWeight = result['bodyWeight'] as double?;

    try {
      await settingsProv.updateProfile(
        gender: newGender,
        bodyWeightKg: newWeight,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.settingsBodyMetricsSaved)),
      );
    } catch (error, stackTrace) {
      elogError('PROFILE_BODY_METRICS_SAVE', error, stackTrace);
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

  void _showSettingsDialog() {
    final loc = AppLocalizations.of(context)!;
    final themePref = context.read<ThemePreferenceProvider>();
    final gymId = context.read<AuthProvider>().gymCode;
    final themeLabel = _currentThemeLabel(loc, themePref, gymId);
    showDialog(
      context: context,
      builder:
          (_) => SimpleDialog(
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
                  _showThemeDialog();
                },
                child: Row(
                  children: [
                    Expanded(child: Text(loc.settingsOptionTheme)),
                    Text(themeLabel),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _showBodyMetricsSheet();
                },
                child: Row(
                  children: [
                    Expanded(child: Text(loc.settingsBodyMetrics)),
                    Text(_bodyMetricsSummary(loc)),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  elogUi('settings_open_creatine', {});
                  _showCreatineSheet();
                },
                child: Row(
                  children: [
                    Expanded(child: Text(loc.settingsCreatineTracker)),
                    Text(context.read<SettingsProvider>().creatineEnabled
                        ? loc.settingsCreatineEnabled
                        : loc.settingsCreatineDisabled),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _showPrivacyDialog();
                },
                child: Text(loc.settingsOptionPublicProfile),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  showChangeUsernameSheet(context);
                },
                child: Text(loc.settingsOptionChangeUsername),
              ),
            ],
          ),
    );
  }

  void _openCalendarPopup(String userId, List<String> trainingDates) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CalendarPopup(
            trainingDates: trainingDates,
            initialYear: DateTime.now().year,
            userId: userId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final xp = context.watch<XpProvider>();
    final userId = auth.userId ?? '';
    const avatarSize = 44.0;

    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    Widget buildBody() {
      if (prov.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (prov.error != null) {
        return Center(child: Text('Fehler: ${prov.error}'));
      }
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.profileTrainingDaysHeading,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ) ??
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openCalendarPopup(userId, prov.trainingDates),
                child: Calendar(
                  trainingDates: prov.trainingDates,
                  showNavigation: false,
                  year: DateTime.now().year,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: brandColor,
        automaticallyImplyLeading: false,
        leadingWidth: avatarSize + AppSpacing.md * 2,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Tooltip(
              message: loc.profileChangeAvatar,
              child: Semantics(
                button: true,
                label: loc.profileChangeAvatar,
                child: GestureDetector(
                  onTap: () => _showProfileXpSheet(auth),
                  child: Builder(builder: (context) {
                    final gymId = context.read<AuthProvider>().gymCode;
                    final path = AvatarCatalog.instance
                        .resolvePathOrFallback(auth.avatarKey,
                            gymId: gymId);
                    final image =
                        Image.asset(path, errorBuilder: (_, __, ___) {
                      if (kDebugMode) {
                        debugPrint('[Avatar] failed to load $path');
                      }
                      return const Icon(Icons.person);
                    });
                    return DailyXpAvatar(
                      image: image.image,
                      size: avatarSize,
                      xp: xp.dailyLevelXp,
                      level: xp.dailyLevel,
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          if (enableFriends)
            Consumer<FriendAlertsProvider>(
              builder: (context, alerts, _) {
                return IconButton(
                  icon: Stack(
                    children: [
                      const BrandGradientIcon(Icons.group),
                      if (alerts.showBadge)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child:
                              CircleAvatar(radius: 4, backgroundColor: Colors.red),
                        ),
                    ],
                  ),
                  tooltip: loc.friends_title,
                  onPressed: () {
                    Navigator.push(context, FriendsHomeScreen.route());
                  },
                );
              },
            ),
          if (context.watch<SettingsProvider>().creatineEnabled)
            IconButton(
              icon: const BrandGradientIcon(Icons.medication),
              tooltip: loc.creatineTitle,
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.creatine);
              },
            ),
          IconButton(
            icon: const BrandGradientIcon(Icons.settings),
            tooltip: loc.settingsIconTooltip,
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const BrandGradientIcon(Icons.logout),
            tooltip: loc.logoutTooltip,
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacementNamed(AppRouter.auth);
            },
          ),
        ],
      ),
      body: DefaultTextStyle.merge(
        style: TextStyle(color: brandColor),
        child: buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _ProfileActionButton(
                    title: loc.profileStatsButtonLabel,
                    subtitle: loc.profileStatsButtonSubtitle,
                    leading: const SizedBox.square(
                      dimension: 48,
                      child: _ProfileStatsLeadingIcon(),
                    ),
                    trailing: const _ProfileStatsSparkline(),
                    showChevron: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileStatsScreen(),
                        ),
                      );
                    },
                    uiLogEvent: 'PROFILE_STATS_CARD_RENDER',
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: _ProfileActionButton(
                    title: loc.profileCommunityButtonTitle,
                    subtitle: loc.profileCommunityButtonSubtitle,
                    leading: const SizedBox.square(
                      dimension: 48,
                      child: _ProfileCommunityLeadingIcon(),
                    ),
                    trailing: const _ProfileCommunityHighlight(),
                    showChevron: false,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.community);
                    },
                    uiLogEvent: 'PROFILE_COMMUNITY_CARD_RENDER',
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: _ProfileActionButton(
                    title: loc.surveyListTitle,
                    subtitle: loc.reportViewSurveysTitle,
                    leading: const SizedBox.square(
                      dimension: 48,
                      child: _ProfileSurveyLeadingIcon(),
                    ),
                    trailing: const _ProfileSurveyHighlight(),
                    showChevron: false,
                    onTap: () {
                      final gymId = context.read<GymProvider>().currentGymId;
                      final userId = context.read<AuthProvider>().userId ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurveyVoteScreen(
                            gymId: gymId,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    uiLogEvent: 'PROFILE_CARD_RENDER',
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

class _ProfileStatsLeadingIcon extends StatelessWidget {
  const _ProfileStatsLeadingIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.08);
    final backgroundColor = theme.scaffoldBackgroundColor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: borderColor),
      ),
      child: Icon(
        Icons.auto_graph,
        size: 28,
        color: brandColor,
      ),
    );
  }
}

class _ProfileCommunityLeadingIcon extends StatelessWidget {
  const _ProfileCommunityLeadingIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.08);
    final backgroundColor = theme.scaffoldBackgroundColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor),
        color: backgroundColor,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.groups_2, color: brandColor, size: 26),
          Positioned(
            right: 6,
            bottom: 6,
            child: Icon(
              Icons.celebration,
              size: 16,
              color: brandColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

const double _profileHighlightHeight = 40;
const double _profileHighlightWidth = 44;

class _ProfileCommunityHighlight extends StatelessWidget {
  const _ProfileCommunityHighlight();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final onBrand = brandTheme?.onBrand ?? theme.colorScheme.onPrimary;
    final shadow = brandTheme?.shadow ??
        const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ];
    final capsulePadding = AppSpacing.xs * 0.5;
    final accentInset = AppSpacing.xs / 4;
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: '${loc.profileCommunityButtonTitle} highlight',
      child: SizedBox(
        height: _profileHighlightHeight,
        width: _profileHighlightWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: shadow,
          ),
          child: Padding(
            padding: EdgeInsets.all(capsulePadding),
            child: ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.groups_3,
                      size: 22,
                      color: onBrand.withOpacity(0.9),
                    ),
                  ),
                  Positioned(
                    top: accentInset,
                    right: accentInset,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: onBrand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSurveyHighlight extends StatelessWidget {
  const _ProfileSurveyHighlight();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final shadow = brandTheme?.shadow ??
        const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ];
    final capsulePadding = AppSpacing.xs * 0.5;
    final strokePadding = AppSpacing.xs / 4;
    final accentInset = AppSpacing.xs / 4;
    final innerPadding = capsulePadding - strokePadding / 2;
    final bubbleColor = theme.colorScheme.onSurface.withOpacity(0.75);
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: '${loc.surveyListTitle} highlight',
      child: SizedBox(
        height: _profileHighlightHeight,
        width: _profileHighlightWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: shadow,
          ),
          child: Padding(
            padding: EdgeInsets.all(strokePadding),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Padding(
                padding: EdgeInsets.all(innerPadding),
                child: ExcludeSemantics(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.forum_outlined,
                          size: 22,
                          color: bubbleColor,
                        ),
                      ),
                      Positioned(
                        top: accentInset,
                        right: accentInset,
                        child: ShaderMask(
                          shaderCallback: (rect) => gradient.createShader(rect),
                          blendMode: BlendMode.srcIn,
                          child: Icon(
                            Icons.task_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSurveyLeadingIcon extends StatelessWidget {
  const _ProfileSurveyLeadingIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.08);
    final backgroundColor = theme.scaffoldBackgroundColor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: borderColor),
      ),
      child: Icon(
        Icons.poll_outlined,
        size: 28,
        color: brandColor,
      ),
    );
  }
}

class _ProfileStatsSparkline extends StatelessWidget {
  const _ProfileStatsSparkline();

  static const _bars = [10.0, 20.0, 14.0, 26.0, 18.0, 30.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final barColor = Color.lerp(brandColor, Colors.white, 0.15) ?? brandColor;

    return SizedBox(
      height: _profileHighlightHeight,
      width: _profileHighlightWidth,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_bars.length, (index) {
            final target = _bars[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: Duration(milliseconds: 500 + index * 90),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: SizedBox(
                      width: 6,
                      height: value,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.trailing,
    this.showChevron = true,
    this.uiLogEvent,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;
  final String? uiLogEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius =
        (brandTheme?.radius ?? BorderRadius.circular(AppRadius.card)) as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return BrandInteractiveCard(
      onTap: onTap,
      uiLogEvent: uiLogEvent,
      borderRadius: radius,
      semanticLabel: '$title, $subtitle',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withOpacity(0.7),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right,
              color: brandColor,
            ),
          ],
        ],
      ),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.currentKey,
    required this.onSelect,
  });

  final String currentKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inventory = context.watch<AvatarInventoryProvider>();
    final theme = Theme.of(context);
    return StreamBuilder<List<AvatarInventoryEntry>>(
      stream: inventory.inventory(auth.userId ?? ''),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AvatarInventoryEntry>[];
        final currentGym = auth.gymCode;
        final Map<String, AvatarInventoryEntry> map = {};
        for (final item in items) {
          final norm = AvatarAssets.normalizeKey(
            item.key,
            currentGymId: currentGym,
          );
          map[norm] = AvatarInventoryEntry(
            key: norm,
            source: item.source,
            createdAt: item.createdAt,
          );
        }
        for (final d in [
          AvatarInventoryEntry(
              key: AvatarKeys.globalDefault, source: 'global_default'),
          AvatarInventoryEntry(
              key: AvatarKeys.globalDefault2, source: 'global_default'),
        ]) {
          map.putIfAbsent(d.key, () => d);
        }
        final entries = map.values.toList()
          ..sort((a, b) {
            if (a.source == 'global_default' &&
                b.source != 'global_default') {
              return -1;
            }
            if (a.source != 'global_default' &&
                b.source == 'global_default') {
              return 1;
            }
            final aTime = a.createdAt?.toDate() ?? DateTime(1970);
            final bTime = b.createdAt?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
        final keys = entries.map((e) => e.key).toList();
        return SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final selected = key == currentKey;
              final label = 'Avatar ${index + 1}';
              final avatar = Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Builder(builder: (context) {
                      final gymId = context.read<AuthProvider>().gymCode;
                      final path = AvatarCatalog.instance.resolvePathOrFallback(
                        key,
                        gymId: gymId,
                      );
                      final image = Image.asset(path, errorBuilder:
                          (_, __, ___) {
                        if (kDebugMode) {
                          debugPrint('[Avatar] failed to load $path');
                        }
                        return const Icon(Icons.person);
                      });
                      return CircleAvatar(
                        radius: 40,
                        backgroundImage: image.image,
                      );
                    }),
                  ),
                  if (selected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                ],
              );
              final child = avatar;
              return Tooltip(
                message: label,
                child: Semantics(
                  label: label,
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    onTap: () => onSelect(key),
                    child: child,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
