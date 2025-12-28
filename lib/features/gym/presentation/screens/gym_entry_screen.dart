import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/analytics/analytics_service.dart';
import 'package:tapem/core/constants.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/core/widgets/offline_banner.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/auth/presentation/theme/auth_theme.dart';
import 'package:tapem/features/auth/presentation/widgets/auth_background.dart';
import 'package:tapem/features/auth/presentation/widgets/glass_card.dart';
import 'package:tapem/features/auth/presentation/widgets/premium_text_field.dart';
import 'package:tapem/features/gym/application/gym_directory_provider.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/l10n/app_localizations.dart';

class GymEntryScreen extends ConsumerStatefulWidget {
  const GymEntryScreen({super.key});

  @override
  ConsumerState<GymEntryScreen> createState() => _GymEntryScreenState();
}

class _GymEntryScreenState extends ConsumerState<GymEntryScreen> {
  final _searchController = TextEditingController();
  bool _isDropdownOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() => _isDropdownOpen = !_isDropdownOpen);
  }

  Future<void> _selectGym(String gymId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await AnalyticsService.logGymSelected(gymId: gymId, source: 'entry');
    await prefs.setString(StorageKeys.preAuthGymId, gymId);
    await prefs.setBool(StorageKeys.hasSeenGymEntry, true);
    await prefs.setString(StorageKeys.lastUsedGymId, gymId);
    Navigator.of(context).pushReplacementNamed(
      AppRouter.gymAccess,
      arguments: gymId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymsAsync = ref.watch(listGymsProvider);
    final gyms = ref.watch(filteredGymsProvider);
    final brand = Theme.of(context).extension<AppBrandTheme>();
    final listMaxHeight = MediaQuery.of(context).size.height * 0.45;
    final query = ref.watch(gymSearchQueryProvider).trim();
    final auth = ref.watch(authControllerProvider);
    final myGyms = auth.gymCodes ?? [];
    final myGymsLabel = myGyms.length <= 1
        ? loc.gymMyTitleSingle
        : loc.gymMyTitleMultiple;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OfflineBanner(),
            const SizedBox(height: 8),
            Text(
              loc.gymEntryTitle,
              textAlign: TextAlign.center,
              style: AuthTheme.headingStyle.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              loc.gymEntrySubtitle,
              textAlign: TextAlign.center,
              style: AuthTheme.bodyStyle.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AuthTheme.spacingM),
            if (auth.isLoggedIn && myGyms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AuthTheme.spacingM),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        myGymsLabel,
                        style: AuthTheme.labelStyle.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final gymId in myGyms)
                        Consumer(
                          builder: (context, ref, _) {
                            final gymAsync = ref.watch(gymByIdProvider(gymId));
                            return gymAsync.when(
                              data: (gym) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: gym.logoUrl != null
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(gym.logoUrl!),
                                        backgroundColor:
                                            Colors.white.withOpacity(0.1),
                                      )
                                    : const CircleAvatar(
                                        child: Icon(
                                          Icons.fitness_center_outlined,
                                        ),
                                      ),
                                title: Text(
                                  gym.name,
                                  style: AuthTheme.bodyStyle,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                onTap: () => _selectGym(gym.id),
                              ),
                              loading: () => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  gymId,
                                  style: AuthTheme.labelStyle.copyWith(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            AnimatedSize(
              duration: AuthTheme.animationDurationMedium,
              curve: Curves.easeOutCubic,
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _toggleDropdown,
                      borderRadius: BorderRadius.circular(
                        AuthTheme.glassBorderRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                loc.gymDropdownLabel,
                                style: AuthTheme.subHeadingStyle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              duration: AuthTheme.animationDurationFast,
                              turns: _isDropdownOpen ? 0.5 : 0.0,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: AuthTheme.animationDurationMedium,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PremiumTextField(
                              label: loc.gymSearchHint,
                              controller: _searchController,
                              prefixIcon: Icons.search,
                              onChanged: (value) {
                                ref.read(gymSearchQueryProvider.notifier).state =
                                    value;
                              },
                            ),
                            if (query.length < 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  loc.gymSearchMinChars,
                                  textAlign: TextAlign.center,
                                  style: AuthTheme.labelStyle.copyWith(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      crossFadeState: _isDropdownOpen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                    ),
                    if (_isDropdownOpen) const Divider(height: 1),
                    if (_isDropdownOpen)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: listMaxHeight),
                        child: gymsAsync.when(
                          data: (_) {
                            final prefs = ref.read(sharedPreferencesProvider);
                            final lastUsedGymId =
                                prefs.getString(StorageKeys.lastUsedGymId);
                            final sortedGyms = _sortGyms(gyms, lastUsedGymId);
                            if (query.length < 3) {
                              return const SizedBox.shrink();
                            }
                            if (sortedGyms.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    loc.gymSearchEmpty,
                                    textAlign: TextAlign.center,
                                    style: AuthTheme.bodyStyle.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: sortedGyms.length,
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                              itemBuilder: (context, index) {
                                final gym = sortedGyms[index];
                                final isLastUsed = gym.id == lastUsedGymId;
                                return AnimatedContainer(
                                  duration: AuthTheme.animationDurationMedium,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isLastUsed ? 12 : 0,
                                    vertical: isLastUsed ? 4 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: isLastUsed && brand != null
                                        ? Border.all(
                                            color: brand.outline.withOpacity(0.6),
                                            width: 1,
                                          )
                                        : null,
                                    gradient: isLastUsed && brand != null
                                        ? LinearGradient(
                                            colors: [
                                              brand.gradient.colors.first.withOpacity(0.18),
                                              brand.gradient.colors.last.withOpacity(0.12),
                                            ],
                                          )
                                        : null,
                                  ),
                                  child: ListTile(
                                    leading: Hero(
                                      tag: 'gym-logo-${gym.id}',
                                      child: gym.logoUrl != null
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(gym.logoUrl!),
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.1),
                                            )
                                          : const CircleAvatar(
                                              child: Icon(Icons.fitness_center_outlined),
                                            ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            gym.name,
                                            style: AuthTheme.bodyStyle,
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: AuthTheme.animationDurationFast,
                                          child: isLastUsed
                                              ? Container(
                                                  key: const ValueKey('last-used'),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    loc.gymLastUsedBadge,
                                                    style: AuthTheme.labelStyle.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(
                                                  key: ValueKey('empty'),
                                                ),
                                        ),
                                      ],
                                    ),
                                    subtitle: null,
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    onTap: () => _selectGym(gym.id),
                                  ),
                                )
                                    .animate(delay: (index * 60).ms)
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.08, end: 0);
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: Colors.white70),
                          ),
                          error: (error, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                loc.authErrorGeneric(error),
                                textAlign: TextAlign.center,
                                style: AuthTheme.bodyStyle.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<GymConfig> _sortGyms(List<GymConfig> gyms, String? lastUsedGymId) {
    if (lastUsedGymId == null || lastUsedGymId.isEmpty) {
      return gyms;
    }
    final sorted = List<GymConfig>.from(gyms);
    sorted.sort((a, b) {
      if (a.id == lastUsedGymId) return -1;
      if (b.id == lastUsedGymId) return 1;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }
}
