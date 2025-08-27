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
  String trainingDayEndsAt(Object hour) {
    return 'Training day ends at $hour:00';
  }

  @override
  String lateWorkoutsCountPrevDay(Object hour) {
    return 'Late workouts count toward previous day (rollover $hour:00)';
  }

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
  String get historyOverviewTitle => 'Overview';

  @override
  String get historyWorkouts => 'Workouts';

  @override
  String get historySetsAvg => 'Sets (Ø)';

  @override
  String get historyHeaviest => 'Heaviest';

  @override
  String get historySessionsChartTitle => 'Sessions over time';

  @override
  String get historyAxisDate => 'Date';

  @override
  String get historyAxisE1rm => 'E1RM';

  @override
  String get historyAxisSessions => 'Sessions';

  @override
  String get historyNoData => 'No data';

  @override
  String get historyE1rmChartSemantics => 'E1RM over time chart';

  @override
  String get historySessionsChartSemantics => 'Sessions over time chart';

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
  String get numberInvalid => 'Enter a number';

  @override
  String get intRequired => 'Integer';

  @override
  String get dropFillBoth => 'Fill both drop fields or clear them.';

  @override
  String get dropWeightTooHigh => 'Drop kg must be less than base';

  @override
  String get dropRepsInvalid => 'Drop reps min 1';

  @override
  String get dropKgFieldLabel => 'Drop KG';

  @override
  String get dropRepsFieldLabel => 'Drop reps';

  @override
  String get newSessionTitle => 'New session';

  @override
  String get pleaseCheckInputs => 'Please check inputs';

  @override
  String get noCompletedSets => 'No completed sets.';

  @override
  String get todayAlreadySaved => 'Already saved today.';

  @override
  String get setRemoved => 'Set removed';

  @override
  String get undo => 'Undo';

  @override
  String get sessionSaved => 'Session saved';

  @override
  String get setCompleteTooltip => 'Complete set';

  @override
  String get setReopenTooltip => 'Reopen set';

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
  String get timerReset => 'Reset';

  @override
  String get timerDuration => 'Duration';

  @override
  String get timerIncrease => 'Increase timer duration';

  @override
  String get timerDecrease => 'Decrease timer duration';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get germanLanguage => 'German';

  @override
  String get englishLanguage => 'English';

  @override
  String get usernameDialogTitle => 'Choose username';

  @override
  String get usernameFieldLabel => 'Username';

  @override
  String get usernameTaken => 'This username is already taken.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetDialogTitle => 'Reset password';

  @override
  String get passwordResetHint => 'Enter your e-mail to receive a reset link.';

  @override
  String get passwordResetSent => 'Password reset email sent.';

  @override
  String get resetPasswordTitle => 'Choose new password';

  @override
  String get newPasswordFieldLabel => 'New password';

  @override
  String get confirmPasswordButton => 'Update password';

  @override
  String get passwordResetSuccess => 'Password changed.';

  @override
  String get settingsDialogTitle => 'Settings';

  @override
  String get settingsOptionLanguage => 'Language';

  @override
  String get settingsOptionPublicProfile => 'Public profile';

  @override
  String get publicProfileDialogTitle => 'Profile visibility';

  @override
  String get publicProfilePublic => 'Public';

  @override
  String get publicProfilePrivate => 'Private';

  @override
  String get multiDeviceBannerText => 'Multi-device mode: only daily XP and device statistics are counted. No XP per muscle group and no leaderboard update.';

  @override
  String get multiDeviceBannerOk => 'OK';

  @override
  String get multiDeviceSessionSaved => 'Session saved. Daily XP and device stats updated.';

  @override
  String get multiDeviceNewExercise => 'Add exercise';

  @override
  String get multiDeviceExerciseListTitle => 'Select exercise';

  @override
  String get multiDeviceNoExercises => 'No exercises found';

  @override
  String get multiDeviceAddExerciseTitle => 'Add exercise';

  @override
  String get multiDeviceEditExerciseTitle => 'Edit exercise';

  @override
  String get multiDeviceNameFieldLabel => 'Name';

  @override
  String get multiDeviceCancel => 'Cancel';

  @override
  String get multiDeviceSave => 'Save';

  @override
  String get multiDeviceEditExerciseButton => 'Edit';

  @override
  String get muscleCategoryChest => 'Chest';

  @override
  String get muscleCategoryShoulders => 'Shoulders';

  @override
  String get muscleCategoryArms => 'Arms';

  @override
  String get muscleCategoryBack => 'Back';

  @override
  String get muscleCategoryCore => 'Core';

  @override
  String get muscleCategoryLegs => 'Legs';

  @override
  String get multiDeviceSearchHint => 'Search exercises...';

  @override
  String get multiDeviceMuscleGroupFilter => 'Filter by muscle group';

  @override
  String get multiDeviceMuscleGroupFilterAll => 'All muscle groups';

  @override
  String get exerciseAddTitle => 'Add exercise';

  @override
  String get exerciseEditTitle => 'Edit exercise';

  @override
  String get exerciseNameLabel => 'Name';

  @override
  String get exerciseMuscleGroupsLabel => 'Muscle groups';

  @override
  String get exerciseSelectedMuscleGroups => 'Selected';

  @override
  String get exerciseSearchMuscleGroupsHint => 'Search muscle groups...';

  @override
  String get exerciseNoMuscleGroups => 'No muscle groups available';

  @override
  String get exerciseEdit_clearAll => 'Clear all';

  @override
  String get exerciseEdit_reset => 'Reset';

  @override
  String get exerciseEdit_discardChangesTitle => 'Discard changes?';

  @override
  String get exerciseEdit_discardChangesMessage => 'Your changes will be lost.';

  @override
  String get exerciseEdit_keepEditing => 'Keep editing';

  @override
  String get exerciseEdit_discard => 'Discard';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get muscleAdminTitle => 'Manage muscle groups';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get assignMuscleGroups => 'Assign muscle groups';

  @override
  String get resetMuscleGroups => 'Reset muscle groups';

  @override
  String get resetMuscleGroupsConfirm => 'Clear primary and secondary muscle groups?';

  @override
  String get muscleGroupTitle => 'Muscle groups';

  @override
  String get muscleTabsPrimary => 'Primary';

  @override
  String get muscleTabsSecondary => 'Secondary';

  @override
  String get reset => 'Reset';

  @override
  String get emptyPrimary => 'No primary muscle groups';

  @override
  String get emptySecondary => 'No secondary muscle groups';

  @override
  String get mustSelectPrimary => 'Select a primary muscle group';

  @override
  String get filterNameChip => 'Name';

  @override
  String get filterMuscleChip => 'Muscle';

  @override
  String a11yMgSelected(Object name) {
    return 'Muscle group: $name, selected';
  }

  @override
  String a11yMgUnselected(Object name) {
    return 'Muscle group: $name, not selected';
  }

  @override
  String get muscleCatUpperFront => 'Upper body - front';

  @override
  String get muscleCatUpperBack => 'Upper body - back';

  @override
  String get muscleCatCore => 'Core';

  @override
  String get muscleCatLower => 'Lower body';

  @override
  String get friends_title => 'Friends';

  @override
  String get friends_tab_my_friends => 'My Friends';

  @override
  String get friends_tab_requests => 'Requests';

  @override
  String get friends_tab_search => 'Search';

  @override
  String get friends_action_add => 'Add';

  @override
  String get friends_action_accept => 'Accept';

  @override
  String get friends_action_decline => 'Decline';

  @override
  String get friends_action_cancel => 'Cancel';

  @override
  String get friends_action_remove => 'Remove';

  @override
  String get friends_snackbar_sent => 'Request sent';

  @override
  String get friends_snackbar_accepted => 'Request accepted';

  @override
  String get friends_snackbar_declined => 'Request declined';

  @override
  String get friends_snackbar_canceled => 'Request canceled';

  @override
  String get friends_snackbar_removed => 'Friend removed';

  @override
  String get friends_empty_incoming => 'No incoming requests';

  @override
  String get friends_empty_outgoing => 'No outgoing requests';

  @override
  String get friends_empty_friends => 'No friends yet';

  @override
  String get friends_empty_search => 'No users found';

  @override
  String get friends_privacy_no_access => 'This user does not share their calendar';
}
