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
  String get gymEntryTitle => 'Choose your gym';

  @override
  String get gymEntrySubtitle => 'Select the studio you want to access.';

  @override
  String get gymMyTitleSingle => 'My Gym';

  @override
  String get gymMyTitleMultiple => 'My Gyms';

  @override
  String get gymDropdownLabel => 'Gyms';

  @override
  String get gymLastUsedBadge => 'Last used';

  @override
  String get gymSearchHint => 'Search gym';

  @override
  String get gymSearchMinChars => 'Enter at least 3 letters to see results.';

  @override
  String get gymSearchEmpty => 'No gyms found for your search.';

  @override
  String gymAccessTitle(Object gymName) {
    return 'Welcome to $gymName';
  }

  @override
  String get gymAccessSubtitle => 'Login or register to continue.';

  @override
  String get gymDemoCta => 'Start demo';

  @override
  String get gymDemoExitCta => 'Sign in';

  @override
  String get gymDemoRestrictedMessage => 'Demo mode is read-only. Sign in to start workouts.';

  @override
  String get gymChangeSelection => 'Change gym';

  @override
  String get gymRegisterMethodTitle => 'How do you want to register?';

  @override
  String gymRegisterMethodSubtitle(Object gymName) {
    return 'Choose how to register for $gymName.';
  }

  @override
  String get gymRegisterWithNfc => 'Register via NFC';

  @override
  String get gymRegisterWithCode => 'Register with gym code';

  @override
  String gymLoginTitle(Object gymName) {
    return 'Login to $gymName';
  }

  @override
  String gymRegisterTitle(Object gymName) {
    return 'Register at $gymName';
  }

  @override
  String get gymNfcHint => 'NFC scan will follow in a later step. You can enter the gym code manually for now.';

  @override
  String gymJoinTitle(Object gymName) {
    return 'Add $gymName';
  }

  @override
  String get gymJoinSubtitle => 'Enter the gym code to add this membership to your account.';

  @override
  String get gymJoinCta => 'Add membership';

  @override
  String get gymAddMembershipTitle => 'Add a gym';

  @override
  String get gymAddMembershipSubtitle => 'Choose the studio you want to add.';

  @override
  String get gymMembershipAlreadyAdded => 'Already added';

  @override
  String get gymSwitchTitle => 'Switch gym';

  @override
  String get gymSwitchSubtitle => 'Select the gym you want to use right now.';

  @override
  String get gymSwitchActiveLabel => 'Active';

  @override
  String get gymAddMembershipCta => 'Add another gym';

  @override
  String get nfcScanTitle => 'Scan NFC';

  @override
  String get nfcScanSubtitle => 'Hold your phone to the NFC tag in the gym.';

  @override
  String get nfcScanWaiting => 'Waiting for scan...';

  @override
  String get nfcScanRetry => 'Scan again';

  @override
  String get nfcScanManual => 'Enter gym code instead';

  @override
  String get nfcUnavailable => 'NFC is not available on this device.';

  @override
  String get nfcInvalidCode => 'No valid NFC code detected.';

  @override
  String get nfcTokenInactive => 'This NFC token is no longer active.';

  @override
  String get nfcScanFailed => 'NFC scan failed. Please try again.';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get loadingErrorLabel => 'Could not load data.';

  @override
  String get settingsSectionGymAccess => 'Gym access';

  @override
  String get settingsOptionSwitchGym => 'Switch gym';

  @override
  String get settingsOptionSwitchGymSubtitle => 'Change your active studio or add another membership.';

  @override
  String gymRemoveTitle(Object gymName) {
    return 'Remove $gymName?';
  }

  @override
  String get gymRemoveMessage => 'This will remove your membership and access to this gym.';

  @override
  String get gymRemoveActiveMessage => 'This is your active gym. You\'ll be switched to another gym after removal.';

  @override
  String get gymRemoveCta => 'Remove';

  @override
  String get gymRemoveLastBlocked => 'You must keep at least one gym membership.';

  @override
  String get cancelButton => 'Cancel';

  @override
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
  String get leaderboardGymTabLabel => 'Gym';

  @override
  String get leaderboardFriendsTabLabel => 'Friends';

  @override
  String get leaderboardGymCardTitle => 'Top 10 in your gym';

  @override
  String get leaderboardFriendsCardTitle => 'Friends leaderboard';

  @override
  String get leaderboardEmptyGym => 'No leaderboard data yet.';

  @override
  String get leaderboardEmptyFriends => 'No friends with XP yet.';

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
  String get missingMembershipError => 'We couldn\'t find an active membership for your account. Please contact your gym or support.';

  @override
  String get invalidGymSelectionError => 'This gym isn\'t linked to your account.';

  @override
  String get membershipSyncError => 'We couldn\'t sync your membership. Please try again.';

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
  String get historyWorkoutsDesc => 'Number of completed workouts for this exercise.';

  @override
  String get historySetsAvg => 'Sets (Ø)';

  @override
  String get historySetsAvgDesc => 'Average number of sets per workout for this exercise.';

  @override
  String get historyHeaviest => 'Best';

  @override
  String get historyHeaviestDesc => 'Your best set shown as kg × reps, based on your strongest set.';

  @override
  String get historySessionsChartTitle => 'Sessions over time';

  @override
  String get historyAxisDate => 'Date';

  @override
  String get historyAxisE1rm => 'E1RM';

  @override
  String get historyE1rmDesc => 'Estimated one-rep max, your calculated max for a single rep.';

  @override
  String get historyAxisSessions => 'Sessions';

  @override
  String get historyNoData => 'No data';

  @override
  String get historyE1rmChartSemantics => 'E1RM over time chart';

  @override
  String get historySessionsChartSemantics => 'Sessions over time chart';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressButtonTitle => 'Progress';

  @override
  String get progressButtonSubtitle => 'Workout history overview';

  @override
  String get progressYearLabel => 'Year';

  @override
  String get progressEmptyTitle => 'No progress data yet';

  @override
  String get progressEmptySubtitle => 'Complete workouts to see your yearly progress.';

  @override
  String get progressLoadMore => 'Show more';

  @override
  String get progressBackfillAction => 'Backfill progress';

  @override
  String get progressBackfillTitle => 'Generate progress data';

  @override
  String get progressBackfillBody => 'This will scan your past workouts and generate yearly progress charts. It may take a moment and uses additional reads.';

  @override
  String get progressBackfillConfirm => 'Start';

  @override
  String get progressBackfillCancel => 'Cancel';

  @override
  String progressBackfillDone(Object sessions, Object exercises) {
    return 'Backfill done: $sessions sessions, $exercises exercises.';
  }

  @override
  String get progressInfoAction => 'How it works';

  @override
  String get progressInfoTitle => 'How progress works';

  @override
  String get progressInfoBody => 'Charts appear when an exercise has at least 3 saved sessions in the selected year. Train and save your workouts to build progress. Use the \"Generate progress data\" button in the top right to refresh your data.';

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
  String get profileCommunityButtonTitle => 'Community';

  @override
  String get profileCommunityButtonSubtitle => 'Shared milestones & live ticker';

  @override
  String get profileStatsTitle => 'Statistics';

  @override
  String get profileStatsTotalTrainingDays => 'Total training days';

  @override
  String get profileStatsAverageTrainingDaysPerWeek => 'Avg. training days per week';

  @override
  String get profileStatsRestTimerLabel => 'Rest timer';

  @override
  String get profileStatsNfcScans => 'NFC scans';

  @override
  String get profileStatsNfcScansSubtitle => 'total scans';

  @override
  String get profileStatsFavoriteExercise => 'Favourite exercise';

  @override
  String get profileStatsFavoriteExerciseDialogTitle => 'Top 5 favourite exercises';

  @override
  String get profileStatsFavoriteExerciseFallback => 'No sessions yet';

  @override
  String get profileStatsPowerliftingButton => 'Powerlifting';

  @override
  String get restStatsTitle => 'Set Pauses';

  @override
  String get restStatsHeadline => 'Overall average';

  @override
  String get restStatsHeroDescription => 'Average rest time across all equipment';

  @override
  String get restStatsActualLabel => 'Avg. rest';

  @override
  String restStatsSampleCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on # sessions',
      one: 'Based on # session',
    );
    return '$_temp0';
  }

  @override
  String restStatsSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# sets recorded',
      one: '# set recorded',
    );
    return '$_temp0';
  }

  @override
  String get restStatsErrorMessage => 'Could not load set pauses.';

  @override
  String get restStatsReloadCta => 'Reload';

  @override
  String get restStatsEmptyMessage => 'No set pauses recorded yet.';

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
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsSectionPersonalization => 'Personalization';

  @override
  String get settingsSectionHealthTracking => 'Health & tracking';

  @override
  String get settingsSectionVisibilityAccount => 'Visibility & account';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsOptionLanguage => 'Language';

  @override
  String get settingsLanguageSystemDefault => 'System default';

  @override
  String get settingsOptionTheme => 'Theme';

  @override
  String get settingsBodyMetrics => 'Body metrics';

  @override
  String get settingsBodyMetricsDialogTitle => 'Body metrics';

  @override
  String get settingsGenderLabel => 'Gender';

  @override
  String get settingsGenderNone => 'Not set';

  @override
  String get settingsGenderFemale => 'Female';

  @override
  String get settingsGenderMale => 'Male';

  @override
  String get settingsGenderDiverse => 'Diverse';

  @override
  String get settingsBodyWeightLabel => 'Body weight (kg)';

  @override
  String get settingsBodyWeightHint => 'e.g. 82.5';

  @override
  String get settingsBodyWeightError => 'Please enter a valid weight';

  @override
  String get settingsBodyMetricsSaved => 'Body metrics saved.';

  @override
  String get settingsBodyMetricsSaveError => 'Could not save body metrics.';

  @override
  String get settingsBodyMetricsSummaryEmpty => 'Not set';

  @override
  String settingsBodyWeightSummary(String value) {
    return '$value kg';
  }

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
  String get settingsThemeAzureSapphire => 'Azure & Sapphire';

  @override
  String get settingsThemeAmberSunset => 'Amber Sunset';

  @override
  String get settingsThemeForestEmerald => 'Forest & Emerald';

  @override
  String get settingsThemeRoyalPlum => 'Royal Plum';

  @override
  String get settingsThemeNeonLime => 'Neon Lime';

  @override
  String get settingsThemeCopperBronze => 'Copper & Bronze';

  @override
  String get settingsThemeArcticSky => 'Arctic Sky';

  @override
  String get settingsThemeEmberInferno => 'Ember Inferno';

  @override
  String get settingsThemeCyberGrape => 'Cyber Grape';

  @override
  String get settingsThemeCitrusPunch => 'Citrus Punch';

  @override
  String get settingsThemeCyberpunkNeon => 'Cyberpunk Neon';

  @override
  String get settingsThemeAnimeBloom => 'Anime Bloom';

  @override
  String get settingsThemeFlameInferno => 'Fire Nation';

  @override
  String get settingsThemeWaterTribe => 'Water Tribe';

  @override
  String get settingsThemeAirNomads => 'Air Nomads';

  @override
  String get settingsThemeEarthKingdom => 'Earth Kingdom';

  @override
  String get settingsThemeMidnightGold => 'Midnight Gold';

  @override
  String get settingsThemeSaveError => 'Could not save theme.';

  @override
  String get settingsOptionPublicProfile => 'Public profile';

  @override
  String get settingsOptionChangeUsername => 'Change username';

  @override
  String settingsUsernameCurrent(String username) {
    return 'Current username: $username';
  }

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
  String get settingsLegalImprint => 'Imprint';

  @override
  String get settingsLegalPrivacy => 'Privacy policy';

  @override
  String get settingsLegalPlaceholderDescription => 'Link will be added soon.';

  @override
  String settingsLegalPlaceholder(String label) {
    return 'Link to $label coming soon.';
  }

  @override
  String get publicProfileDialogTitle => 'Profile visibility';

  @override
  String get publicProfilePublic => 'Public';

  @override
  String get publicProfilePrivate => 'Private';

  @override
  String deviceLeaderboardTitle(String device) {
    return 'King/Queen – $device';
  }

  @override
  String deviceLeaderboardTitleKing(String device) {
    return 'King – $device';
  }

  @override
  String deviceLeaderboardTitleQueen(String device) {
    return 'Queen – $device';
  }

  @override
  String get deviceLeaderboardUnavailable => 'Not available for this device.';

  @override
  String get deviceLeaderboardTabToday => 'Today';

  @override
  String get deviceLeaderboardTabWeek => 'Week';

  @override
  String get deviceLeaderboardTabMonth => 'Month';

  @override
  String get deviceLeaderboardFilterAll => 'All';

  @override
  String get deviceLeaderboardFilterFemale => 'w';

  @override
  String get deviceLeaderboardFilterMale => 'm';

  @override
  String get deviceLeaderboardFilterGenderLabel => 'Gender';

  @override
  String get deviceLeaderboardFilterScoreLabel => 'Scoring';

  @override
  String get deviceLeaderboardFilterAbsolute => 'Absolute';

  @override
  String get deviceLeaderboardFilterRelative => 'Relative';

  @override
  String get deviceLeaderboardError => 'Could not load leaderboard.';

  @override
  String get deviceLeaderboardEmpty => 'No records yet.';

  @override
  String deviceLeaderboardRelativeValue(String value) {
    return 'Relative: $value×BW';
  }

  @override
  String deviceLeaderboardRelativeScore(String value) {
    return '$value×BW';
  }

  @override
  String get deviceLeaderboardTooltip => 'Show King/Queen leaderboard';

  @override
  String get setCardPreviousLabel => 'Previous';

  @override
  String get multiDeviceBannerText => 'Multi-device mode: only daily XP and device statistics are counted. No XP per muscle group and no leaderboard update.';

  @override
  String get multiDeviceBannerOk => 'OK';

  @override
  String get multiDeviceSessionSaved => 'Session saved. Daily XP and device stats updated.';

  @override
  String get storySessionTitle => 'Session Highlights';

  @override
  String get storySessionDailyXpTitle => 'Daily XP';

  @override
  String storySessionDailyXpValue(Object xp) {
    return '$xp XP';
  }

  @override
  String get storySessionDailyXpGrossLabel => 'Gross reward';

  @override
  String get storySessionDailyXpNetLabel => 'XP earned';

  @override
  String get storySessionDailyXpFloorAppliedNotice => 'Includes minimum balance adjustment';

  @override
  String get storySessionDailyXpPreviousTotalLabel => 'Before';

  @override
  String get storySessionDailyXpResultingTotalLabel => 'Now';

  @override
  String storySessionDailyXpLevelValue(int level, String xp) {
    return 'Level $level · $xp XP';
  }

  @override
  String get storySessionDailyXpPenaltiesLabel => 'Penalties';

  @override
  String get storySessionDailyXpBreakdownTitle => 'Today\'s XP breakdown';

  @override
  String get storySessionDailyXpPenaltyTitle => 'Penalties applied';

  @override
  String get storySessionDailyXpComponentBase => 'Base reward';

  @override
  String storySessionDailyXpComponentBaseSubtitle(Object day) {
    return 'Training day #$day';
  }

  @override
  String get storySessionDailyXpComponentComeback => 'Comeback boost';

  @override
  String get storySessionDailyXpComponentStreak => 'Streak bonus';

  @override
  String storySessionDailyXpComponentStreakSubtitle(num streak) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '#-day streak',
      one: '#-day streak',
    );
    return '$_temp0';
  }

  @override
  String get storySessionDailyXpComponentMilestone => 'Milestone reward';

  @override
  String storySessionDailyXpComponentMilestoneSubtitle(Object day) {
    return 'Milestone day $day';
  }

  @override
  String get storySessionDailyXpComponentUnknown => 'Additional reward';

  @override
  String get storySessionDailyXpPenaltyStreakBreak => 'Streak break penalty';

  @override
  String get storySessionDailyXpPenaltyMissedWeek => 'Missed week penalty';

  @override
  String get storySessionDailyXpPenaltyGeneric => 'Penalty';

  @override
  String storySessionDailyXpPenaltyIdleDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '# days without training',
      one: '# day without training',
    );
    return '$_temp0';
  }

  @override
  String storySessionDailyXpPenaltyWeekLabel(Object week) {
    return 'Week $week without training';
  }

  @override
  String get storySessionBadgesTitle => 'Badges';

  @override
  String get storySessionStatsExercisesTitle => 'Exercises';

  @override
  String get storySessionStatsSetsTitle => 'Sets';

  @override
  String get storySessionStatsDurationTitle => 'Duration';

  @override
  String storySessionDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String storySessionDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String storySessionDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String storySessionNewDeviceTitle(Object device) {
    return 'First time on $device';
  }

  @override
  String storySessionNewExerciseTitle(Object device, Object exercise) {
    return 'First time: $exercise on $device';
  }

  @override
  String storySessionNewPrTitle(Object name) {
    return 'New personal record in $name';
  }

  @override
  String storySessionNewPrSubtitle(String weight, String reps) {
    return 'Top PR set: $weight kg × $reps reps';
  }

  @override
  String storySessionNewPrFallback(String value) {
    return 'Estimated 1RM: $value kg';
  }

  @override
  String get storySessionButtonTooltip => 'Show training story';

  @override
  String get storySessionEmptyMessage => 'No highlights available for this day.';

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
  String get commonClose => 'Close';

  @override
  String get commonShare => 'Share';

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
  String get friends_action_chat => 'Chat';

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
  String get friend_chat_empty => 'No messages yet';

  @override
  String get friend_chat_input_hint => 'Write a message';

  @override
  String get friend_chat_send => 'Send message';

  @override
  String get friend_chat_send_error => 'Message could not be sent.';

  @override
  String get friend_chat_login_required => 'Please sign in to chat.';

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
  String get homeTabAdmin => 'Admin';

  @override
  String get homeTabRank => 'Rank';

  @override
  String get homeTabDeals => 'Deals';

  @override
  String get homeTabPlans => 'Plans';

  @override
  String get homeTabNutrition => 'Nutrition';

  @override
  String get nutritionHomeSubtitle => 'Calories, macros, and daily goals at a glance.';

  @override
  String get nutritionHomeGoalsTitle => 'Set daily goals';

  @override
  String get nutritionHomeGoalsSubtitle => 'Define calories and macro distribution.';

  @override
  String get nutritionHomeScanTitle => 'Scan product';

  @override
  String get nutritionHomeScanSubtitle => 'Scan a barcode and add an entry.';

  @override
  String get nutritionHomeCalendarTitle => 'Year calendar';

  @override
  String get nutritionHomeCalendarSubtitle => 'See days under/on/over target.';

  @override
  String get nutritionDayTitle => 'Daily overview';

  @override
  String get nutritionTargetLabel => 'Target';

  @override
  String get nutritionTotalLabel => 'Total';

  @override
  String get nutritionEmptyEntries => 'No entries yet.';

  @override
  String get nutritionEntriesTitle => 'Entries';

  @override
  String get nutritionChangeDateCta => 'Change date';

  @override
  String get nutritionScanTitle => 'Scan product';

  @override
  String get nutritionScanHint => 'Align the barcode within the frame.';

  @override
  String get nutritionScanManualCta => 'Add manually';

  @override
  String get nutritionScanCta => 'Scan product';

  @override
  String get nutritionProductTitle => 'Product';

  @override
  String nutritionProductBarcode(Object code) {
    return 'Barcode: $code';
  }

  @override
  String get nutritionProductOpenOffCta => 'Open in Open Food Facts';

  @override
  String get nutritionProductRetryCta => 'Retry lookup';

  @override
  String get nutritionBarcodeInvalidHint => 'Barcode looks invalid. Please rescan.';

  @override
  String get nutritionProductNotFound => 'Product not found. Add it manually.';

  @override
  String get nutritionProductManualCta => 'Manual entry';

  @override
  String get nutritionProductSaveCta => 'Save product';

  @override
  String get nutritionProductPer100g => 'Per 100 g';

  @override
  String get nutritionProductGramsLabel => 'Grams';

  @override
  String get nutritionProductComputedTitle => 'Calculated for your amount';

  @override
  String get nutritionProductAddCta => 'Add to day';

  @override
  String get nutritionAttributionTitle => 'Data source';

  @override
  String get nutritionAttributionBody => 'Product data provided by Open Food Facts under the ODbL 1.0 license.';

  @override
  String get nutritionAttributionSourceLink => 'Open Food Facts';

  @override
  String get nutritionAttributionLicenseLink => 'ODbL 1.0';

  @override
  String get nutritionAddEntryCta => 'Add entry';

  @override
  String get nutritionEntryTitle => 'Add entry';

  @override
  String get nutritionEntryNameLabel => 'Name';

  @override
  String get nutritionEntryBarcodeLabel => 'Barcode (optional)';

  @override
  String get nutritionEntryKcalLabel => 'Calories';

  @override
  String get nutritionEntryProteinLabel => 'Protein (g)';

  @override
  String get nutritionEntryCarbsLabel => 'Carbs (g)';

  @override
  String get nutritionEntryFatLabel => 'Fat (g)';

  @override
  String get nutritionEntryQtyLabel => 'Quantity (optional)';

  @override
  String get nutritionEntrySaveCta => 'Save entry';

  @override
  String get nutritionEntrySaved => 'Entry saved.';

  @override
  String get nutritionEntrySaveError => 'Could not save entry.';

  @override
  String get nutritionEntryLookupCta => 'Lookup';

  @override
  String get nutritionEntryLookupFound => 'Product loaded.';

  @override
  String get nutritionEntryLookupEmpty => 'No product found.';

  @override
  String get nutritionEntryLookupError => 'Lookup failed.';

  @override
  String get nutritionSearchTitle => 'Search products';

  @override
  String get nutritionSearchHint => 'Search Open Food Facts';

  @override
  String get nutritionSearchCta => 'Search';

  @override
  String get nutritionSearchMinChars => 'Enter at least 2 characters.';

  @override
  String get nutritionSearchEmpty => 'No products found.';

  @override
  String get nutritionSearchError => 'Search failed.';

  @override
  String nutritionSearchMacroLine(Object kcal, Object protein, Object carbs, Object fat) {
    return '$kcal kcal | Protein $protein g | Carbs $carbs g | Fat $fat g';
  }

  @override
  String get nutritionEditGoalCta => 'Edit goals';

  @override
  String get nutritionOpenCalendarCta => 'Open calendar';

  @override
  String get nutritionGoalsTitle => 'Daily goals';

  @override
  String get nutritionGoalsIntro => 'Set a daily calorie target and macro split.';

  @override
  String get nutritionGoalsSaveCta => 'Save goals';

  @override
  String get nutritionGoalsSaved => 'Goals saved.';

  @override
  String get nutritionGoalsSaveError => 'Could not save goals.';

  @override
  String get nutritionGoalsCaloriesLabel => 'Calories';

  @override
  String get nutritionGoalsProteinLabel => 'Protein (g)';

  @override
  String get nutritionGoalsCarbsLabel => 'Carbs (g)';

  @override
  String get nutritionGoalsFatLabel => 'Fat (g)';

  @override
  String get nutritionCalendarTitle => 'Calendar';

  @override
  String get nutritionCalendarIntro => 'Track how often you hit your target throughout the year.';

  @override
  String get nutritionCalendarPlaceholder => 'Calendar visualization will appear here.';

  @override
  String get nutritionLegendUnder => 'Under';

  @override
  String get nutritionLegendOn => 'On target';

  @override
  String get nutritionLegendOver => 'Over';

  @override
  String get nutritionLegendHint => 'Colors indicate the daily status.';

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
  String get reportMembersButtonTitle => 'Members';

  @override
  String get reportMembersButtonSubtitle => 'View active member numbers';

  @override
  String get reportUsageButtonTitle => 'Usage';

  @override
  String get reportUsageButtonSubtitle => 'Visualize device usage data';

  @override
  String get reportFeedbackButtonTitle => 'Feedback';

  @override
  String get reportFeedbackButtonSubtitle => 'Review and manage gym feedback';

  @override
  String get reportSurveysButtonTitle => 'Surveys';

  @override
  String get reportSurveysButtonSubtitle => 'Create and monitor member surveys';

  @override
  String get reportUsageTitle => 'Usage';

  @override
  String get reportFeedbackTitle => 'Feedback';

  @override
  String get reportSurveysTitle => 'Surveys';

  @override
  String get reportMembersTitle => 'Members';

  @override
  String get reportMembersUsageButton => 'Usage';

  @override
  String get reportMembersUsageTitle => 'Usage';

  @override
  String get reportMembersUsageDescription => 'Share of registered members by logged training days.';

  @override
  String get reportMembersUsageNoMembers => 'No members with a membership number available.';

  @override
  String reportMembersUsageBucketSummary(Object label, Object percentage, int count, int total) {
    return '$label: $percentage% ($count of $total)';
  }

  @override
  String get reportMembersMemberNumberColumn => 'Member number';

  @override
  String get reportMembersRoleColumn => 'Role';

  @override
  String get reportMembersTrainingDaysColumn => 'Training days';

  @override
  String get reportMembersCreatedAtColumn => 'Created at';

  @override
  String get reportMembersLoadError => 'We couldn\'t load the member list.';

  @override
  String get reportMembersRoleMember => 'Member';

  @override
  String get reportMembersRoleAdmin => 'Admin';

  @override
  String get reportMembersRoleCoach => 'Coach';

  @override
  String get reportDeviceFilterHint => 'Search devices or descriptions';

  @override
  String get reportUsageRange7Days => 'Last 7 days';

  @override
  String get reportUsageRange30Days => 'Last 30 days';

  @override
  String get reportUsageRange90Days => 'Last 90 days';

  @override
  String get reportUsageRange365Days => 'Last 365 days';

  @override
  String get reportUsageRangeAll => 'All time';

  @override
  String get reportDeviceUsageEmpty => 'No usage data available yet';

  @override
  String get reportDeviceUsageNoMatches => 'No devices match your search';

  @override
  String get reportDeviceUsageError => 'We couldn\'t load the usage data.';

  @override
  String reportDeviceUsageSessions(int count) {
    return '$count sessions';
  }

  @override
  String reportCalendarLogCount(Object date, int count) {
    return 'Logs on $date: $count';
  }

  @override
  String get exerciseDeleteTitle => 'Delete exercise';

  @override
  String exerciseDeleteMessage(Object name) {
    return 'Do you really want to delete the exercise \"$name\"?';
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
  String get xpOverviewTitle => 'Muscle group XP overview';

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
  String get challengeAdminFieldGoalType => 'Challenge goal';

  @override
  String get challengeAdminGoalTypeDeviceSets => 'Device sets';

  @override
  String get challengeAdminGoalTypeWorkoutFrequency => 'Workout frequency';

  @override
  String get challengeAdminFieldType => 'Type';

  @override
  String get challengeAdminFieldWorkoutCount => 'Workouts in period';

  @override
  String get challengeAdminFieldWorkoutWindow => 'Time window';

  @override
  String get challengeAdminWorkoutWindowOneWeek => '1 calendar week';

  @override
  String get challengeAdminWorkoutWindowFourWeeks => '4 calendar weeks';

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
  String challengeDetailGoalDeviceSets(int count) {
    return 'Goal: $count sets';
  }

  @override
  String challengeDetailGoalWorkoutFrequency(int count, int weeks) {
    return 'Goal: $count workouts in $weeks calendar weeks';
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
  String get challengeAdminCreateButton => 'Create challenge';

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
    return 'Do you really want to delete the device \"$name\"?';
  }

  @override
  String get deviceDeleteSuccess => 'Device deleted';

  @override
  String get deviceWriteNfcTooltip => 'Write NFC tag';

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
  String get adminSymbolsBackfillTooltip => 'Backfill usernameLower';

  @override
  String adminSymbolsBackfillSuccess(int count) {
    return 'usernameLower updated: $count';
  }

  @override
  String get adminSymbolsGlobalTitle => 'Global';

  @override
  String get userSymbolsAddTooltip => 'Add symbols';

  @override
  String userSymbolsInventoryTitle(Object username) {
    return 'Inventory of $username';
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
    return 'Duration: $duration. Do you want to keep it running or discard the time?';
  }

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
  String get communityTitle => 'Community';

  @override
  String get communityTabToday => 'Today';

  @override
  String get communityTabWeek => 'Week';

  @override
  String get communityTabMonth => 'Month';

  @override
  String get communityKpiHeadline => 'Community totals';

  @override
  String get communityKpiSessions => 'Sessions';

  @override
  String get communityKpiExercises => 'Exercises';

  @override
  String get communityKpiSets => 'Sets';

  @override
  String get communityKpiReps => 'Reps';

  @override
  String get communityKpiVolume => 'Volume (kg)';

  @override
  String get communityEmptyState => 'No data yet for the selected period.';

  @override
  String get communityErrorState => 'We couldn\'t load the community stats.';

  @override
  String get communityRetryButton => 'Retry';

  @override
  String get communityFeedTitle => 'Live ticker';

  @override
  String get communityFeedEmpty => 'No recent events yet.';

  @override
  String get communityFeedError => 'Live ticker could not be loaded.';

  @override
  String get communityFeedTrainingDayHeadline => 'Training day completed';

  @override
  String get communityCalendarTitle => 'Training days';

  @override
  String get communityCalendarCountOne => '1 person trained on this day.';

  @override
  String communityCalendarCountOther(Object count) {
    return '$count people trained on this day.';
  }

  @override
  String get ownerWorkspaceTitle => 'Owner workspace';

  @override
  String ownerWorkspaceActiveGym(Object gymId) {
    return 'Active gym: $gymId';
  }

  @override
  String ownerWorkspaceGeneratedAt(Object timeLabel) {
    return 'Updated: $timeLabel';
  }

  @override
  String get ownerSectionKpiTitle => 'Studio overview';

  @override
  String get ownerSectionKpiSubtitle => 'All core studio signals at a glance.';

  @override
  String get ownerSectionTasksTitle => 'Today\'s priorities';

  @override
  String get ownerSectionTasksSubtitle => 'These tasks create immediate operational impact.';

  @override
  String get ownerSectionQuickActionsTitle => 'Quick actions';

  @override
  String get ownerSectionQuickActionsSubtitle => 'Direct access to all owner modules without route detours.';

  @override
  String get ownerTasksNone => 'No open priorities. Studio operations are stable.';

  @override
  String get ownerPriorityHigh => 'high';

  @override
  String get ownerPriorityMedium => 'medium';

  @override
  String get ownerPriorityLow => 'low';

  @override
  String get ownerNoAccessSubtitle => 'This area requires gymowner or admin permissions.';

  @override
  String get ownerGymContextMissingTitle => 'Gym context missing';

  @override
  String get ownerGymContextMissingSubtitle => 'Select an active gym first so owner data can be loaded.';

  @override
  String get ownerDashboardLoadErrorTitle => 'Owner dashboard could not be loaded';

  @override
  String ownerDashboardLoadErrorSubtitle(Object error) {
    return 'Please refresh the data. Error: $error';
  }

  @override
  String get ownerNoDataTitle => 'No owner data available yet';

  @override
  String get ownerNoDataSubtitle => 'Create devices and first studio actions so the dashboard can show meaningful signals.';

  @override
  String get ownerMetricMembersLabel => 'Members';

  @override
  String get ownerMetricMembersHelper => 'Registered members in the active gym.';

  @override
  String get ownerMetricDevicesLabel => 'Devices';

  @override
  String get ownerMetricDevicesHelper => 'Available training devices.';

  @override
  String get ownerMetricOpenFeedbackLabel => 'Open feedback';

  @override
  String get ownerMetricOpenFeedbackHelper => 'Feedback entries requiring action.';

  @override
  String get ownerMetricOpenSurveysLabel => 'Active surveys';

  @override
  String get ownerMetricOpenSurveysHelper => 'Running surveys in your gym.';

  @override
  String get ownerMetricActiveChallengesLabel => 'Active challenges';

  @override
  String get ownerMetricActiveChallengesHelper => 'Weekly and monthly challenges currently running.';

  @override
  String ownerTaskOpenFeedbackTitle(int count) {
    return 'Handle $count open feedback item(s)';
  }

  @override
  String get ownerTaskOpenFeedbackSubtitle => 'Unresolved feedback reduces service quality.';

  @override
  String get ownerTaskPlanChallengeTitle => 'Plan a new challenge';

  @override
  String get ownerTaskPlanChallengeSubtitle => 'Active challenges increase training frequency and retention.';

  @override
  String get ownerTaskStartSurveyTitle => 'Start a survey';

  @override
  String get ownerTaskStartSurveySubtitle => 'Collect member feedback today with a short survey.';

  @override
  String get ownerTaskCreateFirstDeviceTitle => 'Create the first device';

  @override
  String get ownerTaskCreateFirstDeviceSubtitle => 'Without devices, key tracking and report data are missing.';

  @override
  String get ownerTaskCheckMembersTitle => 'Review member data';

  @override
  String get ownerTaskCheckMembersSubtitle => 'Low member counts in reports can indicate incomplete data.';

  @override
  String get ownerQuickActionReportSubtitle => 'Analyze usage, member trends, and studio KPIs.';

  @override
  String get ownerQuickActionMembersSubtitle => 'Review member base and start clean-up actions.';

  @override
  String get ownerQuickActionDevicesSubtitle => 'Create, edit, and manage devices.';

  @override
  String get ownerQuickActionFeedbackSubtitle => 'Review and resolve open feedback.';

  @override
  String get ownerQuickActionSurveysSubtitle => 'Create, evaluate, and close surveys.';

  @override
  String get ownerQuickActionChallengesSubtitle => 'Plan challenges and maintain running campaigns.';

  @override
  String get ownerQuickActionDealsTitle => 'Deals';

  @override
  String get ownerQuickActionDealsSubtitle => 'Manage partner offers and promotions.';

  @override
  String get ownerQuickActionAdminSubtitle => 'Open all admin modules in one overview.';

  @override
  String get reportOverviewIntro => 'Key metrics for members, usage, and feedback.';

  @override
  String reportSurveyCountsInline(int openCount, int closedCount) {
    return 'Active: $openCount · Closed: $closedCount';
  }

  @override
  String reportManagementSummarySessions(int count) {
    return '$count sessions were logged in this period.';
  }

  @override
  String get reportManagementSummaryNoSessions => 'No usage sessions are available for the current period yet.';

  @override
  String reportManagementSummaryTopDevice(Object deviceName) {
    return 'Most used device: $deviceName.';
  }

  @override
  String get reportUsageHeatmapTitle => 'Activity heatmap';

  @override
  String get reportUsageHeatmapEmpty => 'No log data is available for the selected heatmap period yet.';

  @override
  String get reportUsageDetailsTitle => 'Details';

  @override
  String get reportUsageSlotMorning => 'Morning';

  @override
  String get reportUsageSlotNoon => 'Noon';

  @override
  String get reportUsageSlotEvening => 'Evening';

  @override
  String get reportUsageWeekdayMon => 'Mon';

  @override
  String get reportUsageWeekdayTue => 'Tue';

  @override
  String get reportUsageWeekdayWed => 'Wed';

  @override
  String get reportUsageWeekdayThu => 'Thu';

  @override
  String get reportUsageWeekdayFri => 'Fri';

  @override
  String get reportUsageWeekdaySat => 'Sat';

  @override
  String get reportUsageWeekdaySun => 'Sun';

  @override
  String get reportUsagePatternEmpty => 'No data is available for typical training times yet.';

  @override
  String reportUsagePatternPeakSummary(Object weekday, Object slot) {
    return 'Highest load: $weekday $slot.';
  }

  @override
  String get reportUsagePatternTitle => 'Pattern by weekday and time of day';

  @override
  String reportUsagePatternCellLabel(Object weekday, Object slot, int count) {
    return '$weekday $slot: $count sessions';
  }

  @override
  String get reportMembersLoading => 'Loading members...';

  @override
  String get reportMembersNoRegisteredMembers => 'No members have been registered yet.';

  @override
  String get reportMembersSummaryTotal => 'Members';

  @override
  String get reportMembersSummaryActive => 'Active members';

  @override
  String get reportMembersSummaryInactive => 'Inactive';

  @override
  String get reportMembersSummaryAtRisk => 'At risk (high)';

  @override
  String get reportMembersSummaryNewMembers => 'New members';

  @override
  String get reportMembersSummaryLoyal => 'Loyal members';

  @override
  String get reportMembersSummaryTrainingDays => 'Training days total';

  @override
  String get reportMembersSegmentActions => 'Actions for group';

  @override
  String get reportMembersSegmentAll => 'All members';

  @override
  String get reportMembersSegmentActive => 'Active members';

  @override
  String get reportMembersSegmentInactive => 'Inactive members';

  @override
  String get reportMembersSegmentAtRisk => 'At-risk members';

  @override
  String get reportMembersSegmentNewMembers => 'New members';

  @override
  String get reportMembersSegmentLoyal => 'Loyal members';

  @override
  String get reportMembersSegmentNoNumbers => 'No member numbers in this group.';

  @override
  String get reportMembersSegmentLargeExportTitle => 'Confirm large export action';

  @override
  String reportMembersSegmentLargeExportBody(int count) {
    return 'You are exporting $count member numbers from \"All members\". Please confirm this sharing is required.';
  }

  @override
  String get reportMembersSegmentLargeExportConfirm => 'Confirm';

  @override
  String reportMembersSegmentActionsFor(Object segmentName) {
    return 'Actions for $segmentName';
  }

  @override
  String reportMembersSegmentCount(int count) {
    return '$count members in this group.';
  }

  @override
  String get reportMembersSegmentCopy => 'Copy member numbers';

  @override
  String get reportMembersSegmentCopied => 'Member numbers copied.';

  @override
  String get reportMembersSegmentShare => 'Share member numbers';

  @override
  String reportMembersSegmentShareBody(Object segmentName, int count, Object numbers) {
    return '$segmentName ($count members)\n\nMember numbers:\n$numbers';
  }

  @override
  String get reportMembersSegmentShareSubject => 'Member segment from report';

  @override
  String get reportMembersSegmentAllShort => 'All';

  @override
  String get reportMembersSegmentActiveShort => 'Active';

  @override
  String get reportMembersSegmentInactiveShort => 'Inactive';

  @override
  String get reportMembersSegmentAtRiskShort => 'At risk';

  @override
  String get reportMembersSegmentNewMembersShort => 'New';

  @override
  String get reportMembersSegmentLoyalShort => 'Loyal';

  @override
  String get reportMembersRiskLow => 'low risk';

  @override
  String get reportMembersRiskMedium => 'medium risk';

  @override
  String get reportMembersRiskHigh => 'high risk';

  @override
  String get reportMembersRiskNewMember => 'new member';

  @override
  String get reportMembersAdminOnlyHint => 'Only admins of this gym can see training-day counts.';

  @override
  String get adminNoAccess => 'No access';

  @override
  String get adminRemoveUsersTitle => 'Remove users';

  @override
  String get adminSearchUsersHint => 'Search users (name)';

  @override
  String adminMemberSince(Object date) {
    return 'Member since: $date';
  }

  @override
  String get adminDeleteUserTitle => 'Delete user and data?';

  @override
  String adminDeleteUserMessage(Object name) {
    return 'The user \"$name\" and all associated data in this gym will be permanently deleted.';
  }

  @override
  String get adminDeleteUserAuditHint => 'This action will be logged in the admin audit and cannot be undone.';

  @override
  String adminDeleteUserSuccess(Object name, Object warning) {
    return 'User $name$warning deleted';
  }

  @override
  String adminDeleteUserError(Object error) {
    return 'Error deleting user: $error';
  }

  @override
  String brandingSelectedFile(Object filename) {
    return 'Selected file: $filename';
  }

  @override
  String get brandingLogoUrlHint => 'Note: Without Cloud Functions, please enter a public logo URL instead.';

  @override
  String get brandingLogoUrlLabel => 'Logo URL (optional)';

  @override
  String get brandingLogoUrlPlaceholder => 'https://...';

  @override
  String get adminDealsDeleteTitle => 'Delete deal?';

  @override
  String adminDealsDeleteMessage(Object name) {
    return 'Do you really want to delete the deal \"$name\"?';
  }

  @override
  String get adminDealsTitle => 'Manage deals';

  @override
  String adminDealsToggleError(Object error) {
    return 'Error updating deal state: $error';
  }

  @override
  String adminDealsLoadError(Object error) {
    return 'Error loading deals: $error';
  }

  @override
  String get adminDealsDeleteAuditHint => 'This change affects deal visibility for members immediately.';

  @override
  String get adminDealsDeleted => 'Deal deleted.';

  @override
  String get adminDealsCreateSuccess => 'Deal created.';

  @override
  String get adminDealsUpdateSuccess => 'Deal updated.';

  @override
  String get adminDealsStatusActive => 'Deal is now active.';

  @override
  String get adminDealsStatusInactive => 'Deal is now inactive.';

  @override
  String get adminDealsRestored => 'Deal restored.';

  @override
  String get adminDealsUndoErrorPrefix => 'Undo failed';

  @override
  String adminDealsDeleteError(Object error) {
    return 'Error deleting deal: $error';
  }

  @override
  String get dealFormCategoryDefault => 'Supplements';

  @override
  String get dealFormCategoryLabel => 'Category';

  @override
  String get dealFormRequiredFieldsError => 'Please fill in all required fields (Partner, Title, Code, Link).';

  @override
  String get dealFormInvalidUrlError => 'Shop link is not a valid URL.';

  @override
  String dealFormSaveError(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get dealFormTitleNew => 'New deal';

  @override
  String get dealFormTitleEdit => 'Edit deal';

  @override
  String get dealFormPartnerLabel => 'Partner Name *';

  @override
  String get dealFormTitleLabel => 'Title *';

  @override
  String get dealFormCodeLabel => 'Discount code *';

  @override
  String get dealFormLinkLabel => 'Shop Link *';

  @override
  String get dealFormImageUrlLabel => 'Image URL';

  @override
  String get dealFormPartnerLogoLabel => 'Partner logo URL';

  @override
  String get dealFormDescriptionLabel => 'Description';

  @override
  String get dealFormPriorityLabel => 'Priority';

  @override
  String get dealFormActiveLabel => 'Deal active?';

  @override
  String get adminDeviceEditTitle => 'Edit device';

  @override
  String get adminDeviceNewTitle => 'Create new device';

  @override
  String adminDeviceUidLabel(Object uid) {
    return 'UID: $uid';
  }

  @override
  String adminDeviceIdLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get adminDeviceNameLabel => 'Name';

  @override
  String get adminDeviceNameHint => 'e.g. Leg press';

  @override
  String get adminDeviceDescLabel => 'Description';

  @override
  String get adminDeviceDescHint => 'Optional (Model, etc.)';

  @override
  String get adminDeviceMultiExerciseLabel => 'Includes multiple exercises?';

  @override
  String get adminDeviceMultiExerciseSubtitle => 'For cable cross or racks';

  @override
  String get adminDeviceDeleteAuditHint => 'Device master data will be removed. Downstream evaluations may be affected.';

  @override
  String get adminDashboardChallengesSubtitle => 'Create & manage challenges';

  @override
  String get adminDashboardSymbolsSubtitle => 'User symbols & ranks';

  @override
  String get adminDashboardRemoveUsersTitle => 'Remove users';

  @override
  String get adminDashboardRemoveUsersSubtitle => 'Clean up test users & data';

  @override
  String get adminDashboardDealsTitle => 'Manage deals';

  @override
  String get adminDashboardDealsSubtitle => 'Maintain sponsors & discounts';

  @override
  String get reportTotalSessions => 'Total sessions';

  @override
  String get reportTopDevice => 'Top device';

  @override
  String reportLogsAtDate(Object date, int count) {
    return 'Logs on $date: $count';
  }

  @override
  String get reportSurveysSubtitle => 'Start surveys and evaluate member feedback.';

  @override
  String get reportFeedbackSubtitle => 'Manage suggestions, complaints, and praise from your members.';

  @override
  String reportSurveysStatus(int open, int closed) {
    return 'Active: $open · Closed: $closed';
  }

  @override
  String get reportGenericError => 'An error has occurred';

  @override
  String get reportNoDataAvailable => 'No data available';

  @override
  String get adminDeviceManufacturerLabel => 'Manufacturer';

  @override
  String get adminDeviceMuscleGroupsLabel => 'Muscle groups';

  @override
  String get adminDeviceCreateButton => 'Create';

  @override
  String get adminDeviceNameError => 'Please enter a name.';

  @override
  String get adminDeviceLoadingError => 'Error loading';

  @override
  String get adminDeviceNoManufacturers => 'No manufacturers activated.';

  @override
  String get adminDeviceManageManufacturers => 'Manage';

  @override
  String get adminDeviceSelectManufacturer => 'Select manufacturer';
}
