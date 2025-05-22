// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addSetButton => 'Add set';

  @override
  String authErrorGeneric(Object message) {
    return 'Error: $message';
  }

  @override
  String get authTitle => 'Sign In / Register';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deviceHistoryTooltip => 'Show history';

  @override
  String get deviceNotFound => 'Device not found';

  @override
  String get emailFieldLabel => 'E-mail';

  @override
  String get emailInvalid => 'Please enter a valid e-mail.';

  @override
  String get invalidEmailError => 'Invalid e-mail address.';

  @override
  String get errorPrefix => 'Error';

  @override
  String get genericUser => 'User';

  @override
  String get gymCodeFieldLabel => 'Gym Code';

  @override
  String get gymCodeHelpLabel => 'Help';

  @override
  String get gymCodeInvalid => 'Invalid gym code.';

  @override
  String get gymCodeLockedMessage => 'Too many failed attempts. Please wait 30 seconds.';

  @override
  String get gymCodeRequired => 'Gym code required.';

  @override
  String get gymNoDevices => 'No devices found.';

  @override
  String get gymTitle => 'Gym';

  @override
  String historyTitle(Object deviceId) {
    return 'History: $deviceId';
  }

  @override
  String get historyChartTitle => 'Workout history';

  @override
  String get historyListTitle => 'Past workouts';

  @override
  String homeWelcome(Object user) {
    return 'Welcome, $user';
  }

  @override
  String get kgRequired => 'kg?';

  @override
  String get lastEntriesTitle => 'Last entries';

  @override
  String get languageDialogTitle => 'Select language';

  @override
  String get loginButton => 'Login';

  @override
  String loginFailed(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get noteFieldLabel => 'Note';

  @override
  String get noteAddTooltip => 'Add note';

  @override
  String get noteEditTooltip => 'Edit note';

  @override
  String get noteModalTitle => 'Device Note';

  @override
  String get noteModalHint => 'Write settings or other details here…';

  @override
  String get noteSaveButton => 'Save';

  @override
  String get noteDeleteTooltip => 'Delete note';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get passwordTooShort => 'Must be at least 6 characters.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileTrainingDaysTitle => 'Your training days of the year';

  @override
  String get repsRequired => 'reps?';

  @override
  String get registerButton => 'Register';

  @override
  String get sampleWorkout1 => 'May 12, 2025 – 3×8 @ 80 kg';

  @override
  String get sampleWorkout2 => 'May 10, 2025 – 3×10 @ 75 kg';

  @override
  String get saveButton => 'Save';

  @override
  String get settingsIconTooltip => 'Settings';

  @override
  String get tabAffiliate => 'Affiliate';

  @override
  String get tabAdmin => 'Admin';

  @override
  String get tabGym => 'Gym';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabReport => 'Report';

  @override
  String get tableHeaderKg => 'kg';

  @override
  String get tableHeaderNumber => 'No.';

  @override
  String get tableHeaderReps => 'Reps';

  @override
  String get timerPauseLabel => 'Rest';

  @override
  String get timerStart => 'Start';

  @override
  String get timerStop => 'Stop';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get germanLanguage => 'German';

  @override
  String get englishLanguage => 'English';
}
