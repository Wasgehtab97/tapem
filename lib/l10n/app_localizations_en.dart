// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tapem';

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
  String get commonOk => 'OK';

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
  String get creatineTitle => 'Creatine';

  @override
  String get creatineTakenToday => 'Taken today';

  @override
  String creatineConfirmForDate(Object date) {
    return 'Confirm for $date';
  }

  @override
  String get creatineRemoveMarking => 'Remove mark';

  @override
  String creatineSaved(Object date) {
    return 'Creatine for $date saved';
  }

  @override
  String creatineRemoved(Object date) {
    return 'Creatine for $date removed';
  }

  @override
  String get creatineTakenYesterday => 'Taken yesterday';

  @override
  String get creatineOnlyTodayOrYesterday => 'Only today or yesterday allowed.';

  @override
  String get creatineNoCreatine => 'No creatine?';

  @override
  String get creatineOpenLinkError => 'Could not open link.';

  @override
  String get signInRequiredError => 'Sign-in required.';

  @override
  String get invalidDateError => 'Invalid date.';

  @override
  String get invalidEmailError => 'Invalid e-mail address.';

  @override
  String get errorPrefix => 'Error';

  @override
  String get genericUser => 'User';

  @override
  String get rankExperience => 'Experience';

  @override
  String get rankDeviceLevel => 'Device level';

  @override
  String get rankMuscleLevel => 'Muscle level';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardRankTab => 'Rank';

  @override
  String get leaderboardChallengesTab => 'Challenges';

  @override
  String get xpInfoTooltip => 'XP info';

  @override
  String get xpInfoTitle => 'XP info';

  @override
  String xpInfoCurrentXp(int xp) {
    return 'XP: $xp';
  }

  @override
  String xpInfoLevel(Object level) {
    return 'Level: $level';
  }

  @override
  String xpInfoProgress(int xpRemaining, int nextLevel) {
    return '$xpRemaining XP to level $nextLevel';
  }

  @override
  String get xpInfoDetails => 'Details';

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
  String get profileTrainingDaysHeading => 'Training days';

  @override
  String get profileStatsButtonLabel => 'Statistics';

  @override
  String get profileStatsButtonSubtitle => 'Dive into your progress highlights';

  @override
  String get profileStatsTitle => 'Statistics';

  @override
  String get profileStatsTotalTrainingDays => 'Total training days';

  @override
  String get profileStatsAverageTrainingDaysPerWeek => 'Avg. training days per week';

  @override
  String get profileStatsFavoriteExercise => 'Favourite exercise';

  @override
  String get profileStatsFavoriteExerciseDialogTitle =>
      'Top 5 favourite exercises';

  @override
  String get profileStatsFavoriteExerciseFallback => 'No sessions yet';

  @override
  String get profileStatsPowerliftingButton => 'Powerlifting';

  @override
  String get repsRequired => 'reps?';

  @override
  String get numberInvalid => 'Enter a number';

  @override
  String get intRequired => 'Integer';

  @override
  String get powerliftingTitle => 'Powerlifting';

  @override
  String get powerliftingAddTooltip => 'Assign devices';

  @override
  String get powerliftingClearTooltip => 'Reset powerlifting board';

  @override
  String get powerliftingClearConfirmTitle => 'Reset powerlifting board?';

  @override
  String get powerliftingClearConfirmMessage => 'This removes all linked devices for your powerlifting board. Do you want to continue?';

  @override
  String get powerliftingClearConfirmAction => 'Reset';

  @override
  String get powerliftingClearSuccess => 'Powerlifting board reset.';

  @override
  String get powerliftingClearError => 'Powerlifting board could not be reset.';

  @override
  String get powerliftingIntro => 'Link every device to its discipline to keep track of your PR progress.';

  @override
  String get powerliftingHeaviestTable => 'Heaviest sets';

  @override
  String get powerliftingE1rmTable => 'E1RM';

  @override
  String get powerliftingEmptyTitle => 'Build your powerlifting board';

  @override
  String get powerliftingEmptyDescription => 'Add devices or exercises for bench press, squat and deadlift to automatically collect your heaviest sets.';

  @override
  String get powerliftingAddButton => 'Add powerlifting source';

  @override
  String get powerliftingDisciplineSheetTitle => 'Choose discipline';

  @override
  String powerliftingAssignmentSheetTitle(String discipline) {
    return 'Select devices and exercises for $discipline';
  }

  @override
  String powerliftingDeviceSheetTitle(String discipline) {
    return 'Select a device for $discipline';
  }

  @override
  String get powerliftingDeviceIsMultiNote => 'Multi device – choose an exercise next';

  @override
  String powerliftingExerciseSheetTitle(String device) {
    return 'Select exercise on $device';
  }

  @override
  String get powerliftingNoGymError => 'Select a gym first to manage powerlifting.';

  @override
  String get powerliftingNoDevicesError => 'No devices found in this gym.';

  @override
  String powerliftingNoExercisesError(String device) {
    return 'Create an exercise on $device first.';
  }

  @override
  String get powerliftingAddError => 'Could not add powerlifting source.';

  @override
  String get powerliftingDuplicateError => 'This device or exercise is already linked.';

  @override
  String get powerliftingAddSuccess => 'Powerlifting source added.';

  @override
  String get powerliftingNoRecords => 'No records yet';

  @override
  String get powerliftingBenchPress => 'Bench press';

  @override
  String get powerliftingSquat => 'Squat';

  @override
  String get powerliftingDeadlift => 'Deadlift';

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
  String get notAllSetsConfirmed => 'Not all sets confirmed.';

  @override
  String get confirmAllSets => 'Confirm All';

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
  String get resumeSessionButton => 'Back to session';

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
  String weightFieldLabel(Object unit) {
    return 'Weight ($unit)';
  }

  @override
  String bodyweightFieldLabel(Object unit) {
    return 'BW + extra ($unit)';
  }

  @override
  String get bodyweightModeActiveLabel => 'Bodyweight mode active';

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
  String get usernameInvalid => 'Invalid username.';

  @override
  String get usernameHelper => '3–20 chars, letters, numbers, spaces.';

  @override
  String usernameLowerPreview(Object lower) {
    return 'Lowercase: $lower';
  }

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
  String get settingsOptionTheme => 'Theme';

  @override
  String get settingsThemeDialogTitle => 'Choose app theme';

  @override
  String get settingsThemeDefault => 'Gym default';

  @override
  String get settingsThemeMintTurquoise => 'Mint & Turquoise';

  @override
  String get settingsThemeMagentaViolet => 'Magenta & Violet';

  @override
  String get settingsThemeRedOrange => 'Red/Orange';

  @override
  String get settingsThemeBlackWhite => 'Black/White';

  @override
  String get settingsThemeSaveError => 'Could not save theme.';

  @override
  String get settingsOptionPublicProfile => 'Public profile';

  @override
  String get settingsOptionChangeUsername => 'Change username';

  @override
  String get settingsCreatineTracker => 'Creatine tracker';

  @override
  String get settingsCreatineEnable => 'Enable';

  @override
  String get settingsCreatineDisable => 'Disable';

  @override
  String get settingsCreatineEnabled => 'Enabled';

  @override
  String get settingsCreatineDisabled => 'Disabled';

  @override
  String get settingsCreatineSavedEnabled => 'Creatine tracker enabled.';

  @override
  String get settingsCreatineSavedDisabled => 'Creatine tracker disabled.';

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
  String get filterRecentChip => 'Recent';

  @override
  String get filterSortAz => 'A→Z';

  @override
  String get filterSortZa => 'Z→A';

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
  String get friends_action_training_days => 'Training days';

  @override
  String get friends_action_open_profile => 'Open profile';

  @override
  String get friends_action_remove => 'Remove';

  @override
  String get friends_remove_title => 'Remove this contact?';

  @override
  String friends_remove_message(Object username) {
    return 'Do you really want to remove $username?';
  }

  @override
  String get friends_remove_yes => 'Remove';

  @override
  String get friends_remove_no => 'Cancel';

  @override
  String get friends_snackbar_sent => 'Request sent';

  @override
  String get friends_snackbar_accepted => 'Request accepted';

  @override
  String get friends_snackbar_declined => 'Request declined';

  @override
  String get friends_snackbar_canceled => 'Request canceled';

  @override
  String get friends_removed_snackbar => 'Contact removed';

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

  @override
  String get friends_cta_self => 'You';

  @override
  String get friends_cta_friend => 'Friend';

  @override
  String get friends_cta_pending => 'Pending';

  @override
  String get friends_action_send => 'Send request';

  @override
  String get friends_search_min_chars => 'Enter at least 2 characters';

  @override
  String get bodyweight => 'Bodyweight';

  @override
  String get bodyweightAbbrev => 'BW';

  @override
  String bodyweightPlus(Object kg) {
    return 'Bodyweight + $kg kg';
  }

  @override
  String get bodyweightToggleTooltip => 'Toggle bodyweight';

  @override
  String get admin_symbols_title => 'Symbols';

  @override
  String get admin_symbols_search_hint => 'Search users';

  @override
  String user_symbols_title(Object username) {
    return 'Symbols of $username';
  }

  @override
  String get inventory_section_title => 'Inventory';

  @override
  String get add_symbols_cta => 'Add';

  @override
  String get gym_library_title => 'Gym Library';

  @override
  String get empty_inventory_hint => 'No symbols in inventory yet';

  @override
  String get empty_gym_library_hint => 'No additional symbols available';

  @override
  String get no_members_found => 'No members found';

  @override
  String get saved_snackbar => 'Saved';

  @override
  String get assign_failed_snackbar => 'Assignment failed';

  @override
  String get removed_snackbar => 'Removed';

  @override
  String get no_permission_symbols => 'No permission to view symbols';

  @override
  String get trainingDetailsDeleteSessionTitle => 'Delete session';

  @override
  String get trainingDetailsDeleteSessionMessage => 'Do you really want to delete this session? All related data will be removed.';

  @override
  String get trainingDetailsDeleteSessionConfirm => 'Delete session';

  @override
  String get trainingDetailsDeleteSessionSuccess => 'Session deleted.';

  @override
  String get trainingDetailsDeleteSessionError => 'Could not delete the session.';

  @override
  String get profileChangeAvatar => 'Change profile picture';

  @override
  String get profilePlayAvatarSound => 'Play profile sound';

  @override
  String get homeTabAdmin => 'Admin';

  @override
  String get homeTabRank => 'Rank';

  @override
  String get homeTabAffiliate => 'Affiliate';

  @override
  String get homeTabPlans => 'Plans';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportFeedbackCardTitle => 'Feedback';

  @override
  String reportFeedbackOpenEntries(int count) {
    return '$count open entries';
  }

  @override
  String get reportFeedbackNoOpenEntries => 'No open feedback';

  @override
  String get feedbackDialogTitle => 'Feedback';

  @override
  String get feedbackTooltip => 'Feedback';

  @override
  String get feedbackPlaceholder => 'Your feedback...';

  @override
  String get feedbackSubmit => 'Send';

  @override
  String get feedbackSent => 'Feedback sent';

  @override
  String get reportCreateSurveyTitle => 'Create survey';

  @override
  String get reportViewSurveysTitle => 'View surveys';

  @override
  String get reportDeviceFilterHint => 'Filter devices';

  @override
  String reportDeviceUsageSessions(int count) {
    return '$count sessions';
  }

  @override
  String get exerciseDeleteTitle => 'Delete exercise';

  @override
  String exerciseDeleteMessage(Object name) {
    return 'Do you really want to delete the exercise "$name"?';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSaveError => 'Failed to save.';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonNoAccess => 'No access';

  @override
  String get xpDeviceTitle => 'Device XP';

  @override
  String get xpOverviewTitle => 'XP overview';

  @override
  String get xpOverviewPeriodLabel => 'Time range:';

  @override
  String get xpOverviewPeriodLast7Days => 'Last 7 days';

  @override
  String get xpOverviewPeriodLast30Days => 'Last 30 days';

  @override
  String get xpOverviewPeriodTotal => 'Total';

  @override
  String get xpOverviewTableHeaderMuscleGroup => 'Muscle group';

  @override
  String get xpOverviewTableHeaderXp => 'XP';

  @override
  String xpOverviewLeaderboardTitle(Object region) {
    return 'Leaderboard: $region';
  }

  @override
  String get challengeAdminTitle => 'Manage challenges';

  @override
  String get challengeAdminErrorFillAllFields => 'Please fill out all fields.';

  @override
  String get challengeAdminFieldRequiredSets => 'Required sets';

  @override
  String get challengeAdminFieldXpReward => 'XP reward';

  @override
  String get challengeAdminFieldType => 'Type';

  @override
  String get challengeTabActive => 'Active';

  @override
  String get challengeTabCompleted => 'Completed';

  @override
  String get challengeEmptyActive => 'No active challenges';

  @override
  String get challengeEmptyCompleted => 'No completed challenges';

  @override
  String challengeDetailXpReward(int xp) {
    return 'XP: $xp';
  }

  @override
  String challengeDetailDevices(Object devices) {
    return 'Devices: $devices';
  }

  @override
  String get challengeAdminTypeWeekly => 'Weekly';

  @override
  String get challengeAdminTypeMonthly => 'Monthly';

  @override
  String get challengeAdminFieldWeek => 'Calendar week';

  @override
  String challengeAdminWeekLabel(int week) {
    return 'CW $week';
  }

  @override
  String get challengeAdminFieldMonth => 'Month';

  @override
  String challengeAdminMonthLabel(int month) {
    return 'Month $month';
  }

  @override
  String get challengeAdminFieldDevices => 'Devices';

  @override
  String get adminAreaTitle => 'Admin area';

  @override
  String get adminAreaNoPermission => 'No admin rights';

  @override
  String get adminDashboardTitle => 'Admin dashboard';

  @override
  String get adminDashboardCreateDeviceDialogTitle => 'Create device';

  @override
  String get adminDashboardMultipleExercises => 'Multiple exercises?';

  @override
  String adminDashboardDeviceIdLabel(Object id) {
    return 'Device ID: $id';
  }

  @override
  String get adminDashboardCreateDevice => 'Create device';

  @override
  String get adminDashboardBranding => 'Branding';

  @override
  String adminSymbolsAddButton(int count) {
    return 'Add ($count)';
  }

  @override
  String adminSymbolsAddSuccess(int count) {
    return 'Added $count symbol(s)';
  }

  @override
  String get adminSymbolsRetryLater => 'No connection – please try again later.';

  @override
  String get adminSymbolsNoGlobalAssets => 'Manifest contains no global assets';

  @override
  String adminSymbolsNoAssetsForTitle(Object title) {
    return 'Manifest contains no $title assets';
  }

  @override
  String get adminSymbolsAllGlobalAssigned => 'All global symbols already assigned.';

  @override
  String adminSymbolsAllTitleAssigned(Object title) {
    return 'All $title symbols already assigned.';
  }

  @override
  String get brandingImageTooLarge => 'Image too large (max 500KB)';

  @override
  String get brandingInvalidConfig => 'Please select valid colours and a logo.';

  @override
  String get brandingPickLogo => 'Choose logo';

  @override
  String get brandingPrimaryColorLabel => 'Primary colour (hex)';

  @override
  String get brandingAccentColorLabel => 'Accent colour (hex)';

  @override
  String get nfcNoCode => 'No NFC code detected';

  @override
  String get nfcNoGymSelected => 'No gym selected';

  @override
  String nfcError(Object error) {
    return 'NFC error: $error';
  }

  @override
  String get surveyThanks => 'Thanks for participating!';

  @override
  String get surveySelectOptionPrompt => 'Please choose an option:';

  @override
  String get surveyClose => 'Close survey';

  @override
  String surveyVotesCountWithPercent(int count, Object percent) {
    return '$count votes ($percent%)';
  }

  @override
  String get surveyListTitle => 'Surveys';

  @override
  String get surveyTabOpen => 'Open';

  @override
  String get surveyTabClosed => 'Completed';

  @override
  String get surveyEmpty => 'No open surveys';

  @override
  String get surveyEmptyClosed => 'No completed surveys';

  @override
  String get surveyResultsTitle => 'Results';

  @override
  String get selectGymTitle => 'Select gym';

  @override
  String get sessionStopTitle => 'End workout?';

  @override
  String sessionStopMessage(Object duration) {
    return 'Duration: $duration. Do you want to save or discard the time?';
  }

  @override
  String get sessionStopResumeAction => 'Back to exercise';

  @override
  String get sessionStopResumeSelectionTitle => 'Choose a session';

  @override
  String numericKeypadSemanticsDigit(Object digit) {
    return 'Key $digit';
  }

  @override
  String get numericKeypadSemanticsDecimal => 'Decimal separator';

  @override
  String get numericKeypadSemanticsDelete => 'Delete';

  @override
  String get numericKeypadSemanticsNext => 'Next';

  @override
  String get numericKeypadSemanticsPrevious => 'Previous';

  @override
  String get numericKeypadSemanticsDuplicate => 'Duplicate previous set';

  @override
  String get numericKeypadSemanticsDecrease => 'Decrease';

  @override
  String get numericKeypadSemanticsIncrease => 'Increase';

  @override
  String get numericKeypadSemanticsHideKeyboard => 'Hide keyboard';

  @override
  String get adminDeviceNfcWritten => 'NFC tag written';

  @override
  String adminDeviceNfcWriteError(Object error) {
    return 'Error writing NFC tag: $error';
  }

  @override
  String get deviceDeleteTooltip => 'Delete device';

  @override
  String get deviceDeleteDialogTitle => 'Delete device?';

  @override
  String deviceDeleteDialogMessage(Object name) {
    return 'Do you really want to delete the device "$name"?';
  }

  @override
  String get deviceDeleteSuccess => 'Device deleted';

  @override
  String get deviceWriteNfcTooltip => 'Write NFC tag';
}
