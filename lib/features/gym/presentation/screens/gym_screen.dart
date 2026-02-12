import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/favorite_devices_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/recent_devices_store.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/features/device/providers/device_exercise_preview_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/common/alphabet_scrollbar.dart';
import 'package:tapem/ui/common/search_and_filters.dart';
import 'package:tapem/ui/devices/device_card.dart';
import 'package:tapem/ui/muscles/muscle_group_display.dart';

import '../../../device/presentation/models/workout_device_selection.dart';

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({
    super.key,
    this.onSelect,
    this.selectionMode = false,
    this.floatingActionButton,
    this.actions,
  });

  final ValueChanged<WorkoutDeviceSelection>? onSelect;
  final bool selectionMode;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen>
    with AutomaticKeepAliveClientMixin {
  String _query = '';
  Set<String> _muscles = {};
  SortOrder _sort = SortOrder.az;
  bool _favoritesOnly = false;
  List<String> _recent = [];
  String? _expandedMultiDeviceId;
  late AutoScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groups = ref.read(muscleGroupProvider);
      groups.loadGroups(context);
    });
  }

  Future<void> _loadRecent(String gymId) async {
    final ids = await RecentDevicesStore.getOrder(gymId);
    if (mounted && !listEquals(ids, _recent)) {
      setState(() => _recent = ids);
    }
  }

  List<Device> _filtered(List<Device> devices, Set<String> favoriteIds) {
    final q = _query.toLowerCase();
    final res = devices
        .where((d) {
          final nameMatch = d.name.toLowerCase().contains(q);
          final subtitleMatch = d.displaySubtitle.toLowerCase().contains(q);
          return nameMatch || subtitleMatch;
        })
        .where((d) => !_favoritesOnly || favoriteIds.contains(d.uid))
        .where((d) {
          if (d.isMulti || _muscles.isEmpty) return true;
          final all = {...d.primaryMuscleGroups, ...d.secondaryMuscleGroups};
          return all.any(_muscles.contains);
        })
        .toList();

    // Sort logic: Recent filter uses recent order, otherwise always A-Z.
    res.sort((a, b) {
      if (_sort == SortOrder.recent) {
        final ai = _recent.indexOf(a.uid);
        final bi = _recent.indexOf(b.uid);
        if (ai == -1 && bi == -1) {
          return a.name.compareTo(b.name);
        }
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      }
      return a.name.compareTo(b.name);
    });
    return res;
  }

  void _scrollToLetter(String letter, List<Device> devices) {
    final index = devices.indexWhere(
      (device) => device.name.toUpperCase().startsWith(letter),
    );

    if (index != -1) {
      _scrollController.scrollToIndex(
        index,
        preferPosition: AutoScrollPosition.begin,
      );
    }
  }

  void _showGuestRestriction() {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.gymDemoRestrictedMessage)));
  }

  Future<void> _openWorkoutSelection({
    required String gymId,
    required String deviceId,
    required String exerciseId,
    required String exerciseName,
  }) async {
    final nav = Navigator.of(context);

    if (widget.onSelect != null) {
      widget.onSelect!(
        WorkoutDeviceSelection(
          gymId: gymId,
          deviceId: deviceId,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
        ),
      );
      return;
    }

    final timer = ref.read(workoutSessionDurationServiceProvider);
    if (timer.isRunning) {
      final userId = ref.read(authControllerProvider).userId;
      if (userId != null) {
        try {
          final controller = ref.read(workoutDayControllerProvider);
          controller.addOrFocusSession(
            gymId: gymId,
            deviceId: deviceId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            userId: userId,
          );
        } catch (_) {
          // Fallback: Navigation still happens.
        }
      }
      nav.pushNamed(AppRouter.home, arguments: 2);
      return;
    }

    nav.pushNamed(
      AppRouter.workoutDay,
      arguments: {
        'gymId': gymId,
        'deviceId': deviceId,
        'exerciseId': exerciseId,
      },
    );
  }

  Future<void> _openExerciseList({
    required String gymId,
    required String deviceId,
  }) async {
    final nav = Navigator.of(context);

    if (widget.onSelect != null) {
      final selection = await nav.push<WorkoutDeviceSelection>(
        MaterialPageRoute(
          builder: (ctx) => ExerciseListScreen(
            gymId: gymId,
            deviceId: deviceId,
            onSelect: (result) => Navigator.of(ctx).pop(result),
          ),
        ),
      );
      if (selection != null) {
        widget.onSelect!(selection);
      }
    } else {
      await nav.pushNamed(
        AppRouter.exerciseList,
        arguments: {'gymId': gymId, 'deviceId': deviceId},
      );
    }

    if (!mounted) return;

    final userId = ref.read(authControllerProvider).userId;
    if (userId != null) {
      ref.invalidate(
        deviceExercisePreviewProvider(
          DeviceExercisePreviewKey(
            gymId: gymId,
            deviceId: deviceId,
            userId: userId,
          ),
        ),
      );
    }
  }

  Future<void> _handleDeviceTap(Device device, String gymId) async {
    final auth = ref.read(authControllerProvider);
    if (auth.isGuest) {
      _showGuestRestriction();
      return;
    }

    final id = device.uid;
    if (device.isMulti) {
      await _openExerciseList(gymId: gymId, deviceId: id);
      return;
    }

    await _openWorkoutSelection(
      gymId: gymId,
      deviceId: id,
      exerciseId: id,
      exerciseName: device.name,
    );
  }

  Future<void> _handleQuickExerciseTap({
    required String gymId,
    required Device device,
    required Exercise exercise,
  }) async {
    final auth = ref.read(authControllerProvider);
    if (auth.isGuest) {
      _showGuestRestriction();
      return;
    }

    setState(() => _expandedMultiDeviceId = null);
    await _openWorkoutSelection(
      gymId: gymId,
      deviceId: device.uid,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
    );
  }

  Future<void> _handleDeviceLongPress(Device device, String gymId) async {
    final auth = ref.read(authControllerProvider);
    if (auth.isGuest) {
      _showGuestRestriction();
      return;
    }
    await ref
        .read(favoriteDevicesProvider)
        .toggleFavorite(gymId: gymId, deviceId: device.uid);
  }

  void _toggleMultiDeviceDropdown({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    final shouldExpand = _expandedMultiDeviceId != deviceId;
    setState(() {
      _expandedMultiDeviceId = shouldExpand ? deviceId : null;
    });

    if (!shouldExpand) return;

    ref.invalidate(
      deviceExercisePreviewProvider(
        DeviceExercisePreviewKey(
          gymId: gymId,
          deviceId: deviceId,
          userId: userId,
        ),
      ),
    );
  }

  Map<String, String> _muscleAbbreviationById(List<MuscleGroup> groups) {
    return {
      for (final group in groups)
        group.id: _abbreviateMuscleGroupName(
          group.name,
          fallback: group.region.name,
        ),
    };
  }

  String _abbreviateMuscleGroupName(
    String rawName, {
    required String fallback,
  }) {
    final name = rawName.trim();
    final source = name.isEmpty ? fallback : name;
    final parts = source
        .split(RegExp(r'[\s\-/]+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return parts
          .take(3)
          .map((part) => part.substring(0, 1))
          .join()
          .toUpperCase();
    }

    final first = parts.isNotEmpty ? parts.first : source;
    final maxLen = first.length >= 3 ? 3 : first.length;
    return first.substring(0, maxLen).toUpperCase();
  }

  String _muscleNameForId(String id, List<MuscleGroup> groups) {
    for (final group in groups) {
      if (group.id == id) {
        return displayNameForMuscleGroup(group.region, group);
      }
    }
    for (final region in MuscleRegion.values) {
      if (region.name == id) {
        return fallbackLabelForRegion(region);
      }
    }
    return id;
  }

  String? _deviceMuscleSummaryText(Device device, List<MuscleGroup> groups) {
    final ids = [
      ...device.primaryMuscleGroups,
      ...device.secondaryMuscleGroups,
    ];
    final seen = <String>{};
    final names = <String>[];
    for (final id in ids) {
      if (!seen.add(id)) continue;
      final label = _muscleNameForId(id, groups).trim();
      if (label.isEmpty) continue;
      names.add(label);
    }
    if (names.isEmpty) return null;
    return names.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context)!;
    final auth = ref.read(authControllerProvider);
    final gymProv = ref.watch(gymProvider);
    final favoriteProv = ref.watch(favoriteDevicesProvider);
    final gymId = auth.gymCode ?? '';
    final userId = auth.userId;
    final muscleGroups = ref.watch(muscleGroupProvider).groups;
    final muscleAbbreviationById = _muscleAbbreviationById(muscleGroups);
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    if (gymId.isNotEmpty &&
        !favoriteProv.hasLoadedGym(gymId) &&
        !favoriteProv.isLoadingGym(gymId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(favoriteDevicesProvider).loadForGym(gymId);
      });
    }

    if (gymProv.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (gymProv.error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            '${loc.errorPrefix}: ${gymProv.error}',
            style: TextStyle(color: brandColor),
          ),
        ),
      );
    }
    if (_sort == SortOrder.recent) {
      _loadRecent(gymId);
    }
    final favoriteIds = favoriteProv.favoriteIdsForGym(gymId);
    final devices = _filtered(gymProv.devices, favoriteIds);

    PreferredSizeWidget? appBar;
    if (widget.selectionMode) {
      appBar = AppBar(
        title: Text(loc.multiDeviceExerciseListTitle),
        actions: widget.actions,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      appBar: appBar,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SearchAndFilters(
                    query: _query,
                    onQuery: (v) => setState(() => _query = v),
                    sort: _sort,
                    onSort: (v) {
                      setState(() => _sort = v);
                      if (v == SortOrder.recent) {
                        _loadRecent(gymId);
                      }
                    },
                    favoritesOnly: _favoritesOnly,
                    onFavoritesOnlyChanged: (value) =>
                        setState(() => _favoritesOnly = value),
                    muscleFilterIds: _muscles,
                    onMuscleFilter: (v) => setState(() => _muscles = v),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async => gymProv.loadGymData(gymId),
                        child: devices.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.5,
                                    child: Center(
                                      child: Text(
                                        _favoritesOnly
                                            ? 'Keine Favoriten gefunden.'
                                            : loc.gymNoDevices,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: devices.length,
                                itemBuilder: (ctx, i) {
                                  final device = devices[i];
                                  final quickUserId = userId;
                                  final canShowQuickDropdown =
                                      device.isMulti && quickUserId != null;
                                  final isExpanded =
                                      canShowQuickDropdown &&
                                      _expandedMultiDeviceId == device.uid;
                                  final previewKey = canShowQuickDropdown
                                      ? DeviceExercisePreviewKey(
                                          gymId: gymId,
                                          deviceId: device.uid,
                                          userId: quickUserId,
                                        )
                                      : null;
                                  final previewState =
                                      isExpanded && previewKey != null
                                      ? ref.watch(
                                          deviceExercisePreviewProvider(
                                            previewKey,
                                          ),
                                        )
                                      : null;

                                  return AutoScrollTag(
                                    key: ValueKey(i),
                                    controller: _scrollController,
                                    index: i,
                                    child: Padding(
                                      // Extra right spacing so the alphabet bar
                                      // does not overlap card actions.
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        4,
                                        40,
                                        4,
                                      ),
                                      child: DeviceCard(
                                        device: device,
                                        onTap: () =>
                                            _handleDeviceTap(device, gymId),
                                        onLongPress: () =>
                                            _handleDeviceLongPress(
                                              device,
                                              gymId,
                                            ),
                                        margin: EdgeInsets.zero,
                                        isFavorite: favoriteIds.contains(
                                          device.uid,
                                        ),
                                        muscleSummaryText: device.isMulti
                                            ? null
                                            : _deviceMuscleSummaryText(
                                                device,
                                                muscleGroups,
                                              ),
                                        quickAction: canShowQuickDropdown
                                            ? _MultiExerciseToggleButton(
                                                expanded: isExpanded,
                                                onPressed: () =>
                                                    _toggleMultiDeviceDropdown(
                                                      gymId: gymId,
                                                      deviceId: device.uid,
                                                      userId: quickUserId,
                                                    ),
                                              )
                                            : null,
                                        extraBottom: previewState == null
                                            ? null
                                            : _MultiExerciseQuickList(
                                                state: previewState,
                                                accentColor: brandColor,
                                                muscleAbbreviationById:
                                                    muscleAbbreviationById,
                                                emptyText:
                                                    loc.multiDeviceNoExercises,
                                                onRetry: () {
                                                  if (previewKey != null) {
                                                    ref.invalidate(
                                                      deviceExercisePreviewProvider(
                                                        previewKey,
                                                      ),
                                                    );
                                                  }
                                                },
                                                onExerciseTap: (exercise) =>
                                                    _handleQuickExerciseTap(
                                                      gymId: gymId,
                                                      device: device,
                                                      exercise: exercise,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (devices.isNotEmpty)
                        Positioned(
                          right: 4,
                          top: 8,
                          bottom: 8,
                          child: AlphabetScrollbar(
                            onLetterSelected: (letter) =>
                                _scrollToLetter(letter, devices),
                          ),
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

class _MultiExerciseToggleButton extends StatelessWidget {
  const _MultiExerciseToggleButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withOpacity(0.7);

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 21,
        splashRadius: 18,
        color: color,
        tooltip: AppLocalizations.of(context)!.multiDeviceExerciseListTitle,
        icon: Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
        ),
      ),
    );
  }
}

class _MultiExerciseQuickList extends StatelessWidget {
  const _MultiExerciseQuickList({
    required this.state,
    required this.accentColor,
    required this.muscleAbbreviationById,
    required this.emptyText,
    required this.onRetry,
    required this.onExerciseTap,
  });

  final AsyncValue<List<Exercise>> state;
  final Color accentColor;
  final Map<String, String> muscleAbbreviationById;
  final String emptyText;
  final VoidCallback onRetry;
  final ValueChanged<Exercise> onExerciseTap;

  String? _muscleSuffix(Exercise exercise) {
    final ids = exercise.muscleGroupIds.isNotEmpty
        ? exercise.muscleGroupIds
        : [
            ...exercise.primaryMuscleGroupIds,
            ...exercise.secondaryMuscleGroupIds,
          ];
    final seen = <String>{};
    final labels = <String>[];

    for (final id in ids) {
      if (!seen.add(id)) continue;
      final short = muscleAbbreviationById[id];
      if (short == null || short.isEmpty) continue;
      labels.add(short);
      if (labels.length == 3) break;
    }

    if (labels.isEmpty) return null;
    return labels.join('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.scaffoldBackgroundColor.withOpacity(0.22),
        border: Border.all(color: accentColor.withOpacity(0.16)),
      ),
      child: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.errorPrefix,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                splashRadius: 16,
              ),
            ],
          ),
        ),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                emptyText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.72),
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < exercises.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: accentColor.withOpacity(0.12),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onExerciseTap(exercises[i]),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercises[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          if (_muscleSuffix(exercises[i]) case final suffix?)
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 34,
                                maxWidth: 74,
                              ),
                              child: Text(
                                suffix,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.25,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.48),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: accentColor.withOpacity(0.82),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
