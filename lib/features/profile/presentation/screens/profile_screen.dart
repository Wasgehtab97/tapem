// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/features/friends/providers/friend_alerts_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
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
        context.read<FriendAlertsProvider>().listen(uid);
        context.read<SettingsProvider>().load(uid);
        final gymId = context.read<AuthProvider>().gymCode ?? '';
        context.read<XpProvider>().watchStatsDailyXp(gymId, uid);
      }
    });
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

  void _showProfileXpSheet(AuthProvider auth) {
    final xpProvider = context.read<XpProvider>();
    final profile = PublicProfile(
      uid: auth.userId ?? '',
      username: auth.userName ?? auth.userEmail ?? 'Tapem',
      primaryGymCode: auth.gymCode,
      avatarKey: auth.avatarKey,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DailyXpCard(
              profile: profile,
              level: xpProvider.dailyLevel,
              xpInLevel: xpProvider.dailyLevelXp,
              totalXp: xpProvider.statsDailyXp,
            ),
          ),
        );
      },
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
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.settings);
            },
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
