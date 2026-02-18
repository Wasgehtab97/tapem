import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';

enum ActiveWorkoutTimerStyle { glass, neon, stealth }

class ActiveWorkoutTimerStyleController
    extends StateNotifier<ActiveWorkoutTimerStyle> {
  ActiveWorkoutTimerStyleController({
    required SharedPreferences preferences,
    required String? uid,
  }) : _preferences = preferences,
       _uid = uid,
       super(_loadInitialStyle(preferences: preferences, uid: uid));

  static const String _prefsKeyBase = 'active_workout_timer_style_v1';

  final SharedPreferences _preferences;
  final String? _uid;

  String get _prefsKey =>
      (_uid?.isEmpty ?? true) ? _prefsKeyBase : '${_prefsKeyBase}_$_uid';

  Future<void> setStyle(ActiveWorkoutTimerStyle style) async {
    if (state == style) return;
    state = style;
    await _preferences.setInt(_prefsKey, style.index);
  }

  static ActiveWorkoutTimerStyle _loadInitialStyle({
    required SharedPreferences preferences,
    required String? uid,
  }) {
    final key = uid == null || uid.isEmpty
        ? _prefsKeyBase
        : '${_prefsKeyBase}_$uid';
    final storedIndex = preferences.getInt(key);
    if (storedIndex == null) return ActiveWorkoutTimerStyle.glass;
    if (storedIndex < 0 ||
        storedIndex >= ActiveWorkoutTimerStyle.values.length) {
      return ActiveWorkoutTimerStyle.glass;
    }
    return ActiveWorkoutTimerStyle.values[storedIndex];
  }
}

final activeWorkoutTimerStyleProvider =
    StateNotifierProvider<
      ActiveWorkoutTimerStyleController,
      ActiveWorkoutTimerStyle
    >((ref) {
      final preferences = ref.watch(sharedPreferencesProvider);
      final uid = ref.watch(
        authControllerProvider.select((auth) => auth.userId),
      );
      return ActiveWorkoutTimerStyleController(
        preferences: preferences,
        uid: uid,
      );
    });
