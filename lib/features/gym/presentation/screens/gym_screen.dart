import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/recent_devices_store.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/common/search_and_filters.dart';
import 'package:tapem/ui/devices/device_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/ui/common/alphabet_scrollbar.dart';

import '../../../device/presentation/models/workout_device_selection.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({
    super.key,
    this.onSelect,
    this.selectionMode = false,
  });

  final ValueChanged<WorkoutDeviceSelection>? onSelect;
  final bool selectionMode;

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen>
    with AutomaticKeepAliveClientMixin {
  String _query = '';
  Set<String> _muscles = {};
  SortOrder _sort = SortOrder.az;
  List<String> _recent = [];
  final ScrollController _scrollController = ScrollController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final gym = context.read<GymProvider>();
      final groups = context.read<MuscleGroupProvider>();
      final code = auth.gymCode;
      if (code != null && code.isNotEmpty) {
        gym.loadGymData(code);
        groups.loadGroups(context);
      }
    });
  }

  Future<void> _loadRecent(String gymId) async {
    final ids = await RecentDevicesStore.getOrder(gymId);
    if (mounted && !listEquals(ids, _recent)) {
      setState(() => _recent = ids);
    }
  }

  List<Device> _filtered(List<Device> devices) {
    final q = _query.toLowerCase();
    var res = devices.where((d) {
      final nameMatch = d.name.toLowerCase().contains(q);
      final brandMatch = d.description.toLowerCase().contains(q);
      return nameMatch || brandMatch;
    }).where((d) {
      if (d.isMulti || _muscles.isEmpty) return true;
      final all = {...d.primaryMuscleGroups, ...d.secondaryMuscleGroups};
      return all.any(_muscles.contains);
    }).toList();
    
    // Sort logic: Recent filter uses recent order, otherwise always A-Z
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
      // Always A-Z when not using Recent filter
      return a.name.compareTo(b.name);
    });
    return res;
  }

  void _scrollToLetter(String letter, List<Device> devices) {
    // Find the first device that starts with this letter
    final index = devices.indexWhere(
      (device) => device.name.toUpperCase().startsWith(letter),
    );
    
    if (index == -1 || !_scrollController.hasClients) {
      return;
    }

    // Use a more accurate calculation based on actual card dimensions
    // Card height (~80-100px) + vertical padding (16px) = ~96-116px per item
    // We'll use a conservative estimate and let the scroll settle naturally
    const estimatedItemHeight = 108.0;
    final targetPosition = index * estimatedItemHeight;
    
    // Clamp to valid scroll range
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedPosition = targetPosition.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final gymProv = context.watch<GymProvider>();
    final gymId = auth.gymCode ?? '';
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

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
    final devices = _filtered(gymProv.devices);

    PreferredSizeWidget? appBar;
    if (widget.selectionMode) {
      appBar = AppBar(
        title: Text(loc.multiDeviceExerciseListTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(
                brandColor.withOpacity(0.08),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
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
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(child: Text(loc.gymNoDevices)),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: devices.length,
                                itemBuilder: (ctx, i) {
                                  final d = devices[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: DeviceCard(
                                      device: d,
                                      onTap: () async {
                                        final nav = Navigator.of(context);
                                        final idStr = d.uid;
                                        if (widget.onSelect != null) {
                                          if (d.isMulti) {
                                            final selection = await nav
                                                .push<WorkoutDeviceSelection>(
                                              MaterialPageRoute(
                                                builder: (ctx) => ExerciseListScreen(
                                                  gymId: gymId,
                                                  deviceId: idStr,
                                                  onSelect: (result) =>
                                                      Navigator.of(ctx).pop(result),
                                                ),
                                              ),
                                            );
                                            if (selection != null) {
                                              widget.onSelect!(selection);
                                            }
                                          } else {
                                            widget.onSelect!(
                                              WorkoutDeviceSelection(
                                                gymId: gymId,
                                                deviceId: idStr,
                                                exerciseId: idStr,
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                        if (d.isMulti) {
                                          nav.pushNamed(
                                            AppRouter.exerciseList,
                                            arguments: {
                                              'gymId': gymId,
                                              'deviceId': idStr,
                                            },
                                          );
                                        } else {
                                          nav.pushNamed(
                                            AppRouter.workoutDay,
                                            arguments: {
                                              'gymId': gymId,
                                              'deviceId': idStr,
                                              'exerciseId': idStr,
                                            },
                                          );
                                        }
                                      },
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
                            onLetterSelected: (letter) => _scrollToLetter(letter, devices),
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

