// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_action_tile.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import '../widgets/calendar.dart';
import '../widgets/calendar_popup.dart';
import '../../../survey/presentation/screens/survey_vote_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friends_home_screen.dart';
import '../widgets/change_username_sheet.dart';
import 'package:tapem/app_router.dart';

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
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return AvatarPicker(
          currentKey: auth.avatarKey,
          onSelect: (key) async {
            Navigator.pop(context);
            try {
              await auth.setAvatarKey(key);
            } catch (_) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fehler beim Speichern')),
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
                    SnackBar(content: Text('Fehler beim Speichern.')),
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
                    SnackBar(content: Text('Fehler beim Speichern.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    final loc = AppLocalizations.of(context)!;
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
    final userId = auth.userId ?? '';
    const avatarSize = 44.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Text(loc.profileTitle)),
            Positioned(
              left: AppSpacing.md,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: Tooltip(
                    message: 'Profilbild ändern',
                    child: Semantics(
                      button: true,
                      label: 'Profilbild ändern',
                      child: GestureDetector(
                        onTap: () => _showAvatarSheet(auth),
                        child: Builder(builder: (context) {
                          final gymId =
                              context.read<AuthProvider>().gymCode;
                          final path = AvatarCatalog.instance.pathForKey(
                            auth.avatarKey,
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
                            radius: avatarSize / 2,
                            backgroundImage: image.image,
                            child: const Icon(Icons.person),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (enableFriends)
            Consumer<FriendsProvider>(
              builder: (context, friends, _) {
                final showBadge = friends.pendingCount > 0;
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.group),
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
              icon: const Icon(Icons.medication),
              tooltip: loc.creatineTitle,
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.creatine);
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: loc.settingsIconTooltip,
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: loc.logoutTooltip,
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacementNamed(AppRouter.auth);
            },
          ),
        ],
      ),
      body:
          prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.error != null
              ? Center(child: Text('Fehler: ${prov.error}'))
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
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
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SizedBox(
            width: double.infinity,
            child: BrandActionTile(
              title: 'Umfragen',
              centerTitle: true,
              dense: true,
              minVerticalPadding: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
              variant: BrandActionTileVariant.outlined,
              showChevron: false,
              uiLogEvent: 'PROFILE_CARD_RENDER',
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
    return StreamBuilder<List<String>>(
      stream: inventory.inventoryKeys(auth.userId ?? ''),
      builder: (context, snapshot) {
        final inv = snapshot.data ?? const <String>[];
        final List<String> keys = inv.isEmpty
            ? AvatarCatalog.instance
                .listGlobal()
                .map((e) => e.key)
                .toList()
            : inv;
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
                      final path = AvatarCatalog.instance.pathForKey(
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
                        child: const Icon(Icons.person),
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
