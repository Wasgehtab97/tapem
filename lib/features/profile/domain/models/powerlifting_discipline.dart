// lib/features/profile/domain/models/powerlifting_discipline.dart

/// Represents the three core powerlifting disciplines supported by the app.
enum PowerliftingDiscipline {
  benchPress,
  squat,
  deadlift,
}

extension PowerliftingDisciplineX on PowerliftingDiscipline {
  /// Stable identifier used for Firestore persistence.
  String get id {
    switch (this) {
      case PowerliftingDiscipline.benchPress:
        return 'bench_press';
      case PowerliftingDiscipline.squat:
        return 'squat';
      case PowerliftingDiscipline.deadlift:
        return 'deadlift';
    }
  }

  /// Human readable ordering for UI presentation.
  int get sortOrder {
    switch (this) {
      case PowerliftingDiscipline.benchPress:
        return 0;
      case PowerliftingDiscipline.squat:
        return 1;
      case PowerliftingDiscipline.deadlift:
        return 2;
    }
  }

  static PowerliftingDiscipline? fromId(String? value) {
    switch (value) {
      case 'bench_press':
        return PowerliftingDiscipline.benchPress;
      case 'squat':
        return PowerliftingDiscipline.squat;
      case 'deadlift':
        return PowerliftingDiscipline.deadlift;
      default:
        return null;
    }
  }
}
