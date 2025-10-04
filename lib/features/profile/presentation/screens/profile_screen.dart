// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/brand_theme_preset.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/widgets/brand_action_tile.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadTrainingDates(context);
      final uid = context.read<AuthProvider>().userId;
      if (uid != null) {
        context.read<FriendsProvider>().listen(uid);
        context.read<SettingsProvider>().load(uid);
        final gymId = context.read<AuthProvider>().gymCode ?? '';
        context.read<XpProvider>().watchStatsDailyXp(gymId, uid);
      }
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

  void _showAvatarSheet(AuthProvider auth) {
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
            BrandGradientText(
              loc.profileTrainingDaysHeading,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
                  onTap: () => _showAvatarSheet(auth),
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
            Consumer<FriendsProvider>(
              builder: (context, friends, _) {
                final showBadge = friends.pendingCount > 0;
                return IconButton(
                  icon: Stack(
                    children: [
                      const BrandGradientIcon(Icons.group),
                      if (showBadge)
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
                  child: _SurveyButton(
                    title: loc.surveyListTitle,
                    subtitle: loc.reportViewSurveysTitle,
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
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: BrandActionTile(
                    leading: const _ProfileStatsLeadingIcon(),
                    title: loc.profileStatsButtonLabel,
                    subtitle: loc.profileStatsButtonSubtitle,
                    minVerticalPadding: AppSpacing.xs,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileStatsScreen(),
                        ),
                      );
                    },
                    trailing: const _ProfileStatsSparkline(),
                    variant: BrandActionTileVariant.gradient,
                    showChevron: false,
                    uiLogEvent: 'PROFILE_STATS_CARD_RENDER',
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
  const _ProfileStatsLeadingIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final glowColor = gradient.colors.last;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const BrandGradientIcon(
        Icons.auto_graph,
        size: 28,
      ),
    );
  }
}

class _ProfileStatsSparkline extends StatelessWidget {
  const _ProfileStatsSparkline({super.key});

  static const _bars = [10.0, 20.0, 14.0, 26.0, 18.0, 30.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient =
        theme.extension<BrandOnColors>()?.onGradient ?? Colors.black;
    final barColor = Color.lerp(onGradient, Colors.white, 0.6) ?? onGradient;

    return Row(
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
    );
  }
}

class _SurveyButton extends StatefulWidget {
  const _SurveyButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_SurveyButton> createState() => _SurveyButtonState();
}

class _SurveyButtonState extends State<_SurveyButton> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    elogUi('PROFILE_CARD_RENDER', {'title': widget.title});
  }

  void _handleHighlight(bool value) {
    if (value == _isPressed || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius =
        (brandTheme?.radius ?? BorderRadius.circular(AppRadius.card)) as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final overlay = brandTheme?.pressedOverlay ?? onSurface.withOpacity(0.08);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final restingBorder = onSurface.withOpacity(0.12);
    final activeBorder = brandColor.withOpacity(0.45);
    final borderColor =
        Color.lerp(restingBorder, activeBorder, _isPressed ? 1 : 0)!;
    final shadowColor = theme.shadowColor.withOpacity(_isPressed ? 0.08 : 0.16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        splashColor: overlay.withOpacity(0.3),
        highlightColor: Colors.transparent,
        onHighlightChanged: _handleHighlight,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: radius,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: _isPressed ? 10 : 20,
                  offset: Offset(0, _isPressed ? 6 : 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _isPressed ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: overlay.withOpacity(0.35),
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: onSurface.withOpacity(0.06),
                          border: Border.all(
                            color: brandColor.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.poll_outlined,
                          color: onSurface.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: brandColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurface.withOpacity(0.7),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.chevron_right,
                        color: onSurface.withOpacity(0.55),
                      ),
                    ],
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
