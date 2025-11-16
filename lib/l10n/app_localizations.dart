import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Fallback application title for the home screen
  ///
  /// In en, this message translates to:
  /// **'Tapem'**
  String get appTitle;

  /// Button label to add a new set
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSetButton;

  /// Generic authentication error
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String authErrorGeneric(Object message);

  /// Title on the auth screen
  ///
  /// In en, this message translates to:
  /// **'Sign In / Register'**
  String get authTitle;

  /// Label for the cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Label for a generic OK action
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Tooltip for the history button on device screen
  ///
  /// In en, this message translates to:
  /// **'Show history'**
  String get deviceHistoryTooltip;

  /// Error when the device cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Device not found'**
  String get deviceNotFound;

  /// Label for the e-mail text field
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get emailFieldLabel;

  /// Validation message for invalid e-mail
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid e-mail.'**
  String get emailInvalid;

  /// Info about end of training day
  ///
  /// In en, this message translates to:
  /// **'Training day ends at {hour}:00'**
  String trainingDayEndsAt(Object hour);

  /// Tooltip for late workouts
  ///
  /// In en, this message translates to:
  /// **'Late workouts count toward previous day (rollover {hour}:00)'**
  String lateWorkoutsCountPrevDay(Object hour);

  /// No description provided for @creatineTitle.
  ///
  /// In en, this message translates to:
  /// **'Creatine'**
  String get creatineTitle;

  /// No description provided for @creatineTakenToday.
  ///
  /// In en, this message translates to:
  /// **'Taken today'**
  String get creatineTakenToday;

  /// No description provided for @creatineConfirmForDate.
  ///
  /// In en, this message translates to:
  /// **'Confirm for {date}'**
  String creatineConfirmForDate(Object date);

  /// No description provided for @creatineRemoveMarking.
  ///
  /// In en, this message translates to:
  /// **'Remove mark'**
  String get creatineRemoveMarking;

  /// No description provided for @creatineSaved.
  ///
  /// In en, this message translates to:
  /// **'Creatine for {date} saved'**
  String creatineSaved(Object date);

  /// No description provided for @creatineRemoved.
  ///
  /// In en, this message translates to:
  /// **'Creatine for {date} removed'**
  String creatineRemoved(Object date);

  /// No description provided for @creatineTakenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Taken yesterday'**
  String get creatineTakenYesterday;

  /// No description provided for @creatineOnlyTodayOrYesterday.
  ///
  /// In en, this message translates to:
  /// **'Only today or yesterday allowed.'**
  String get creatineOnlyTodayOrYesterday;

  /// No description provided for @creatineNoCreatine.
  ///
  /// In en, this message translates to:
  /// **'No creatine?'**
  String get creatineNoCreatine;

  /// No description provided for @creatineOpenLinkError.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get creatineOpenLinkError;

  /// No description provided for @signInRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required.'**
  String get signInRequiredError;

  /// No description provided for @invalidDateError.
  ///
  /// In en, this message translates to:
  /// **'Invalid date.'**
  String get invalidDateError;

  /// Error when e-mail address is malformed
  ///
  /// In en, this message translates to:
  /// **'Invalid e-mail address.'**
  String get invalidEmailError;

  /// Prefix for error displays
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// Fallback display for unknown user
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get genericUser;

  /// Title card for daily experience on rank tab
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get rankExperience;

  /// Title card for device stats on rank tab
  ///
  /// In en, this message translates to:
  /// **'Device level'**
  String get rankDeviceLevel;

  /// Title card for muscle group stats on rank tab
  ///
  /// In en, this message translates to:
  /// **'Muscle level'**
  String get rankMuscleLevel;

  /// App bar title for the leaderboard
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// Tab label for ranking view
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get leaderboardRankTab;

  /// Tab label for challenges view
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get leaderboardChallengesTab;

  /// Toggle label for gym leaderboard
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get leaderboardGymTabLabel;

  /// Toggle label for friends leaderboard
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get leaderboardFriendsTabLabel;

  /// Title for the gym leaderboard card
  ///
  /// In en, this message translates to:
  /// **'Top 10 in your gym'**
  String get leaderboardGymCardTitle;

  /// Title for the friends leaderboard card
  ///
  /// In en, this message translates to:
  /// **'Friends leaderboard'**
  String get leaderboardFriendsCardTitle;

  /// Empty state for gym leaderboard
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data yet.'**
  String get leaderboardEmptyGym;

  /// Empty state for friends leaderboard
  ///
  /// In en, this message translates to:
  /// **'No friends with XP yet.'**
  String get leaderboardEmptyFriends;

  /// Tooltip for the XP info button
  ///
  /// In en, this message translates to:
  /// **'XP info'**
  String get xpInfoTooltip;

  /// Title of the XP info dialog
  ///
  /// In en, this message translates to:
  /// **'XP info'**
  String get xpInfoTitle;

  /// Label for current XP in the XP dialog
  ///
  /// In en, this message translates to:
  /// **'XP: {xp}'**
  String xpInfoCurrentXp(int xp);

  /// Label for the current level in the XP dialog
  ///
  /// In en, this message translates to:
  /// **'Level: {level}'**
  String xpInfoLevel(Object level);

  /// Progress message towards the next level
  ///
  /// In en, this message translates to:
  /// **'{xpRemaining} XP to level {nextLevel}'**
  String xpInfoProgress(int xpRemaining, int nextLevel);

  /// Button to open XP details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get xpInfoDetails;

  /// Label for the gym code input
  ///
  /// In en, this message translates to:
  /// **'Gym Code'**
  String get gymCodeFieldLabel;

  /// Label for gym code help action
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get gymCodeHelpLabel;

  /// Error when gym code is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid gym code.'**
  String get gymCodeInvalid;

  /// Snackbar when gym code is locked due to too many attempts
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please wait 30 seconds.'**
  String get gymCodeLockedMessage;

  /// Validation when gym code is blank
  ///
  /// In en, this message translates to:
  /// **'Gym code required.'**
  String get gymCodeRequired;

  /// Error when no membership exists for the account
  ///
  /// In en, this message translates to:
  /// **"We couldn't find an active membership for your account. Please contact your gym or support."**
  String get missingMembershipError;

  /// Error when a gym outside of the user's account is selected
  ///
  /// In en, this message translates to:
  /// **"This gym isn't linked to your account."**
  String get invalidGymSelectionError;

  /// Error when membership sync fails
  ///
  /// In en, this message translates to:
  /// **"We couldn't sync your membership. Please try again."**
  String get membershipSyncError;

  /// Message when there are no devices in the gym
  ///
  /// In en, this message translates to:
  /// **'No devices found.'**
  String get gymNoDevices;

  /// Title of the gym overview screen
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gymTitle;

  /// Title of the history screen including device ID
  ///
  /// In en, this message translates to:
  /// **'History: {deviceId}'**
  String historyTitle(Object deviceId);

  /// Heading for the workout history chart
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get historyChartTitle;

  /// Heading for the list of past workouts
  ///
  /// In en, this message translates to:
  /// **'Past workouts'**
  String get historyListTitle;

  /// Heading for history overview section
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get historyOverviewTitle;

  /// KPI label for workout count
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get historyWorkouts;

  /// KPI label for average sets per session
  ///
  /// In en, this message translates to:
  /// **'Sets (Ø)'**
  String get historySetsAvg;

  /// KPI label for heaviest weight
  ///
  /// In en, this message translates to:
  /// **'Heaviest'**
  String get historyHeaviest;

  /// Heading for sessions over time chart
  ///
  /// In en, this message translates to:
  /// **'Sessions over time'**
  String get historySessionsChartTitle;

  /// Axis title for date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get historyAxisDate;

  /// Axis title for E1RM chart
  ///
  /// In en, this message translates to:
  /// **'E1RM'**
  String get historyAxisE1rm;

  /// Axis title for sessions chart
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get historyAxisSessions;

  /// Placeholder when no history data is available
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get historyNoData;

  /// Semantics label for E1RM chart
  ///
  /// In en, this message translates to:
  /// **'E1RM over time chart'**
  String get historyE1rmChartSemantics;

  /// Semantics label for sessions chart
  ///
  /// In en, this message translates to:
  /// **'Sessions over time chart'**
  String get historySessionsChartSemantics;

  /// Greeting on the Home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome, {user}'**
  String homeWelcome(Object user);

  /// Validation when weight is missing
  ///
  /// In en, this message translates to:
  /// **'kg?'**
  String get kgRequired;

  /// Title for the last entries list
  ///
  /// In en, this message translates to:
  /// **'Last entries'**
  String get lastEntriesTitle;

  /// Title of the language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get languageDialogTitle;

  /// Label for the Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Message when login fails with exception
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// Tooltip for the logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTooltip;

  /// Label for the note field
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteFieldLabel;

  /// Tooltip for the add-note button
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get noteAddTooltip;

  /// Tooltip for the edit-note button
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEditTooltip;

  /// Title of the device note modal
  ///
  /// In en, this message translates to:
  /// **'Device Note'**
  String get noteModalTitle;

  /// Placeholder text in the note modal
  ///
  /// In en, this message translates to:
  /// **'Write settings or other details here…'**
  String get noteModalHint;

  /// Label for the save button in the note modal
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get noteSaveButton;

  /// Tooltip for the delete-note button in the note modal
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get noteDeleteTooltip;

  /// Snackbar message after successful save
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// Label for the password text field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldLabel;

  /// Validation message for too short password
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters.'**
  String get passwordTooShort;

  /// Title of the profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Heading for the calendar on profile screen
  ///
  /// In en, this message translates to:
  /// **'Your training days of the year'**
  String get profileTrainingDaysTitle;

  /// Short heading for the training days calendar on the profile
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get profileTrainingDaysHeading;

  /// Button label on profile screen to open the statistics page
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStatsButtonLabel;

  /// Subtitle for the statistics call-to-action on the profile screen
  ///
  /// In en, this message translates to:
  /// **'Dive into your progress highlights'**
  String get profileStatsButtonSubtitle;

  /// Button label on profile screen that opens the community page
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get profileCommunityButtonTitle;

  /// Subtitle for the community call-to-action on the profile screen
  ///
  /// In en, this message translates to:
  /// **'Shared milestones & live ticker'**
  String get profileCommunityButtonSubtitle;

  /// Title of the profile statistics page
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStatsTitle;

  /// KPI label for total number of training days
  ///
  /// In en, this message translates to:
  /// **'Total training days'**
  String get profileStatsTotalTrainingDays;

  /// KPI label for average training days per week
  ///
  /// In en, this message translates to:
  /// **'Avg. training days per week'**
  String get profileStatsAverageTrainingDaysPerWeek;

  /// Label for the rest timer tile in profile statistics
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get profileStatsRestTimerLabel;

  /// KPI label for favourite exercise
  ///
  /// In en, this message translates to:
  /// **'Favourite exercise'**
  String get profileStatsFavoriteExercise;

  /// Dialog title that shows the top five favourite exercises
  ///
  /// In en, this message translates to:
  /// **'Top 5 favourite exercises'**
  String get profileStatsFavoriteExerciseDialogTitle;

  /// Fallback text when there is no favourite exercise
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get profileStatsFavoriteExerciseFallback;

  /// Button label that opens the powerlifting overview
  ///
  /// In en, this message translates to:
  /// **'Powerlifting'**
  String get profileStatsPowerliftingButton;

  /// Title of the set pause statistics page
  ///
  /// In en, this message translates to:
  /// **'Set Pauses'**
  String get restStatsTitle;

  /// Headline for the aggregated rest metric
  ///
  /// In en, this message translates to:
  /// **'Overall average'**
  String get restStatsHeadline;

  /// Subtitle describing the aggregated rest insight
  ///
  /// In en, this message translates to:
  /// **'Average rest time across all equipment'**
  String get restStatsHeroDescription;

  /// Label for the average rest value
  ///
  /// In en, this message translates to:
  /// **'Avg. rest'**
  String get restStatsActualLabel;

  /// Helper text indicating how many sessions contribute to the metric
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {Based on # session} other {Based on # sessions}}'**
  String restStatsSampleCount(num count);

  /// Indicates how many sets are included in a stat
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# set recorded} other {# sets recorded}}'**
  String restStatsSetCount(num count);

  /// Error message when rest statistics fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load set pauses.'**
  String get restStatsErrorMessage;

  /// Call-to-action to reload the rest statistics
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get restStatsReloadCta;

  /// Shown when there are no rest statistics
  ///
  /// In en, this message translates to:
  /// **'No set pauses recorded yet.'**
  String get restStatsEmptyMessage;

  /// Validation when reps are missing
  ///
  /// In en, this message translates to:
  /// **'reps?'**
  String get repsRequired;

  /// Validation when a number is expected
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get numberInvalid;

  /// Validation when an integer is expected
  ///
  /// In en, this message translates to:
  /// **'Integer'**
  String get intRequired;

  /// Title of the powerlifting statistics page
  ///
  /// In en, this message translates to:
  /// **'Powerlifting'**
  String get powerliftingTitle;

  /// Tooltip for the add button on the powerlifting page
  ///
  /// In en, this message translates to:
  /// **'Assign devices'**
  String get powerliftingAddTooltip;

  /// Tooltip for the reset button on the powerlifting page
  ///
  /// In en, this message translates to:
  /// **'Reset powerlifting board'**
  String get powerliftingClearTooltip;

  /// Confirmation dialog title before clearing assignments
  ///
  /// In en, this message translates to:
  /// **'Reset powerlifting board?'**
  String get powerliftingClearConfirmTitle;

  /// Confirmation dialog message before clearing assignments
  ///
  /// In en, this message translates to:
  /// **'This removes all linked devices for your powerlifting board. Do you want to continue?'**
  String get powerliftingClearConfirmMessage;

  /// Confirmation dialog action to clear assignments
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get powerliftingClearConfirmAction;

  /// Snackbar shown after clearing assignments
  ///
  /// In en, this message translates to:
  /// **'Powerlifting board reset.'**
  String get powerliftingClearSuccess;

  /// Snackbar shown when clearing assignments fails
  ///
  /// In en, this message translates to:
  /// **'Powerlifting board could not be reset.'**
  String get powerliftingClearError;

  /// Introductory text on the powerlifting page
  ///
  /// In en, this message translates to:
  /// **'Link every device to its discipline to keep track of your PR progress.'**
  String get powerliftingIntro;

  /// Label for the heaviest set table view
  ///
  /// In en, this message translates to:
  /// **'Heaviest sets'**
  String get powerliftingHeaviestTable;

  /// Label for the E1RM table view
  ///
  /// In en, this message translates to:
  /// **'E1RM'**
  String get powerliftingE1rmTable;

  /// Title shown when no powerlifting sources are configured
  ///
  /// In en, this message translates to:
  /// **'Build your powerlifting board'**
  String get powerliftingEmptyTitle;

  /// Description shown when there are no powerlifting assignments
  ///
  /// In en, this message translates to:
  /// **'Add devices or exercises for bench press, squat and deadlift to automatically collect your heaviest sets.'**
  String get powerliftingEmptyDescription;

  /// Button label in the empty state to add a source
  ///
  /// In en, this message translates to:
  /// **'Add powerlifting source'**
  String get powerliftingAddButton;

  /// Bottom sheet title when selecting the discipline
  ///
  /// In en, this message translates to:
  /// **'Choose discipline'**
  String get powerliftingDisciplineSheetTitle;

  /// Bottom sheet title when selecting multiple devices and exercises
  ///
  /// In en, this message translates to:
  /// **'Select devices and exercises for {discipline}'**
  String powerliftingAssignmentSheetTitle(String discipline);

  /// Bottom sheet title when choosing a device
  ///
  /// In en, this message translates to:
  /// **'Select a device for {discipline}'**
  String powerliftingDeviceSheetTitle(String discipline);

  /// Subtitle for multi devices in the selection sheet
  ///
  /// In en, this message translates to:
  /// **'Multi device – choose an exercise next'**
  String get powerliftingDeviceIsMultiNote;

  /// Bottom sheet title when choosing an exercise
  ///
  /// In en, this message translates to:
  /// **'Select exercise on {device}'**
  String powerliftingExerciseSheetTitle(String device);

  /// Snackbar message when no gym is selected
  ///
  /// In en, this message translates to:
  /// **'Select a gym first to manage powerlifting.'**
  String get powerliftingNoGymError;

  /// Snackbar message when no devices are available
  ///
  /// In en, this message translates to:
  /// **'No devices found in this gym.'**
  String get powerliftingNoDevicesError;

  /// Snackbar message when a multi device has no exercises
  ///
  /// In en, this message translates to:
  /// **'Create an exercise on {device} first.'**
  String powerliftingNoExercisesError(String device);

  /// Fallback error when assigning a source fails
  ///
  /// In en, this message translates to:
  /// **'Could not add powerlifting source.'**
  String get powerliftingAddError;

  /// Error shown when the source already exists
  ///
  /// In en, this message translates to:
  /// **'This device or exercise is already linked.'**
  String get powerliftingDuplicateError;

  /// Confirmation when a powerlifting source is added
  ///
  /// In en, this message translates to:
  /// **'Powerlifting source added.'**
  String get powerliftingAddSuccess;

  /// Placeholder when no records exist for a discipline
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get powerliftingNoRecords;

  /// Label for bench press discipline
  ///
  /// In en, this message translates to:
  /// **'Bench press'**
  String get powerliftingBenchPress;

  /// Label for squat discipline
  ///
  /// In en, this message translates to:
  /// **'Squat'**
  String get powerliftingSquat;

  /// Label for deadlift discipline
  ///
  /// In en, this message translates to:
  /// **'Deadlift'**
  String get powerliftingDeadlift;

  /// Validation when only one drop field is filled
  ///
  /// In en, this message translates to:
  /// **'Fill both drop fields or clear them.'**
  String get dropFillBoth;

  /// Validation when drop kg >= base
  ///
  /// In en, this message translates to:
  /// **'Drop kg must be less than base'**
  String get dropWeightTooHigh;

  /// Validation when drop reps < 1
  ///
  /// In en, this message translates to:
  /// **'Drop reps min 1'**
  String get dropRepsInvalid;

  /// Label for drop kg field
  ///
  /// In en, this message translates to:
  /// **'Drop KG'**
  String get dropKgFieldLabel;

  /// Label for drop reps field
  ///
  /// In en, this message translates to:
  /// **'Drop reps'**
  String get dropRepsFieldLabel;

  /// Heading for new session
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSessionTitle;

  /// Snackbar when form is invalid
  ///
  /// In en, this message translates to:
  /// **'Please check inputs'**
  String get pleaseCheckInputs;

  /// Snackbar when no sets are completed
  ///
  /// In en, this message translates to:
  /// **'No completed sets.'**
  String get noCompletedSets;

  /// Dialog title when sets are unconfirmed
  ///
  /// In en, this message translates to:
  /// **'Not all sets confirmed.'**
  String get notAllSetsConfirmed;

  /// Button to confirm all sets
  ///
  /// In en, this message translates to:
  /// **'Confirm All'**
  String get confirmAllSets;

  /// Error when a session has already been saved today
  ///
  /// In en, this message translates to:
  /// **'Already saved today.'**
  String get todayAlreadySaved;

  /// Snackbar after removing a set
  ///
  /// In en, this message translates to:
  /// **'Set removed'**
  String get setRemoved;

  /// Undo action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Snackbar after successful save
  ///
  /// In en, this message translates to:
  /// **'Session saved'**
  String get sessionSaved;

  /// Tooltip for completing a set
  ///
  /// In en, this message translates to:
  /// **'Complete set'**
  String get setCompleteTooltip;

  /// Tooltip when set is completed
  ///
  /// In en, this message translates to:
  /// **'Reopen set'**
  String get setReopenTooltip;

  /// Label for the Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Example workout in the list
  ///
  /// In en, this message translates to:
  /// **'May 12, 2025 – 3×8 @ 80 kg'**
  String get sampleWorkout1;

  /// Example workout in the list
  ///
  /// In en, this message translates to:
  /// **'May 10, 2025 – 3×10 @ 75 kg'**
  String get sampleWorkout2;

  /// Label for the save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Label for the button that resumes the active device session
  ///
  /// In en, this message translates to:
  /// **'Back to session'**
  String get resumeSessionButton;

  /// Tooltip for the settings icon
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsIconTooltip;

  /// Label for the Affiliate tab
  ///
  /// In en, this message translates to:
  /// **'Affiliate'**
  String get tabAffiliate;

  /// Label for the Admin tab
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get tabAdmin;

  /// Label for the Gym tab
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get tabGym;

  /// Label for the Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// Label for the Report tab
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get tabReport;

  /// Table header for weight column
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get tableHeaderKg;

  /// Table header for number column
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get tableHeaderNumber;

  /// Table header for reps column
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get tableHeaderReps;

  /// Label for the standard weight input field
  ///
  /// In en, this message translates to:
  /// **'Weight ({unit})'**
  String weightFieldLabel(Object unit);

  /// Label for the weight input field when bodyweight mode is active
  ///
  /// In en, this message translates to:
  /// **'BW + extra ({unit})'**
  String bodyweightFieldLabel(Object unit);

  /// Indicator shown when bodyweight mode is enabled
  ///
  /// In en, this message translates to:
  /// **'Bodyweight mode active'**
  String get bodyweightModeActiveLabel;

  /// Prefix label for the rest timer
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get timerPauseLabel;

  /// Label for timer start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStart;

  /// Label for timer stop button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get timerStop;

  /// Abbreviation for seconds
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsAbbreviation;

  /// Label for timer reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get timerReset;

  /// Label for timer duration dropdown
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get timerDuration;

  /// Tooltip for increasing timer duration
  ///
  /// In en, this message translates to:
  /// **'Increase timer duration'**
  String get timerIncrease;

  /// Tooltip for decreasing timer duration
  ///
  /// In en, this message translates to:
  /// **'Decrease timer duration'**
  String get timerDecrease;

  /// Error when no user is found
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// Error when password is wrong
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// Label for German language
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get germanLanguage;

  /// Label for English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// Title of the username dialog
  ///
  /// In en, this message translates to:
  /// **'Choose username'**
  String get usernameDialogTitle;

  /// Label for username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameFieldLabel;

  /// Error when username exists
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get usernameTaken;

  /// Error for invalid username
  ///
  /// In en, this message translates to:
  /// **'Invalid username.'**
  String get usernameInvalid;

  /// Helper text for username rules
  ///
  /// In en, this message translates to:
  /// **'3–20 chars, letters, numbers, spaces.'**
  String get usernameHelper;

  /// Preview of lowercased username
  ///
  /// In en, this message translates to:
  /// **'Lowercase: {lower}'**
  String usernameLowerPreview(Object lower);

  /// Link to open password reset dialog
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Title for password reset dialog
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get passwordResetDialogTitle;

  /// Hint text in password reset dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your e-mail to receive a reset link.'**
  String get passwordResetHint;

  /// Snackbar message after sending reset email
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get passwordResetSent;

  /// Title of password reset screen
  ///
  /// In en, this message translates to:
  /// **'Choose new password'**
  String get resetPasswordTitle;

  /// Label for new password field
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordFieldLabel;

  /// Button to confirm new password
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get confirmPasswordButton;

  /// Snackbar after successful password reset
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordResetSuccess;

  /// Title for the settings dialog
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsDialogTitle;

  /// Title for the dedicated settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// Heading for personalization settings
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get settingsSectionPersonalization;

  /// Heading for health and tracking settings
  ///
  /// In en, this message translates to:
  /// **'Health & tracking'**
  String get settingsSectionHealthTracking;

  /// Heading for visibility/account settings
  ///
  /// In en, this message translates to:
  /// **'Visibility & account'**
  String get settingsSectionVisibilityAccount;

  /// Heading for legal links
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// Settings option to change language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsOptionLanguage;

  /// Label for system default language option
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystemDefault;

  /// Settings option to change the app theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsOptionTheme;

  /// Settings option to edit gender and body weight
  ///
  /// In en, this message translates to:
  /// **'Body metrics'**
  String get settingsBodyMetrics;

  /// Title for the body metrics dialog
  ///
  /// In en, this message translates to:
  /// **'Body metrics'**
  String get settingsBodyMetricsDialogTitle;

  /// Label for the gender selector
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get settingsGenderLabel;

  /// Option to clear the gender
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsGenderNone;

  /// Female gender
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settingsGenderFemale;

  /// Male gender
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settingsGenderMale;

  /// Diverse gender option
  ///
  /// In en, this message translates to:
  /// **'Diverse'**
  String get settingsGenderDiverse;

  /// Label for the body weight field
  ///
  /// In en, this message translates to:
  /// **'Body weight (kg)'**
  String get settingsBodyWeightLabel;

  /// Hint for the body weight field
  ///
  /// In en, this message translates to:
  /// **'e.g. 82.5'**
  String get settingsBodyWeightHint;

  /// Validation error when the weight is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get settingsBodyWeightError;

  /// Snackbar after saving body metrics
  ///
  /// In en, this message translates to:
  /// **'Body metrics saved.'**
  String get settingsBodyMetricsSaved;

  /// Snackbar when saving body metrics fails
  ///
  /// In en, this message translates to:
  /// **'Could not save body metrics.'**
  String get settingsBodyMetricsSaveError;

  /// Summary text when no body metrics are stored
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsBodyMetricsSummaryEmpty;

  /// Formats the body weight summary
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String settingsBodyWeightSummary(String value);

  /// Title for the theme selection dialog
  ///
  /// In en, this message translates to:
  /// **'Choose app theme'**
  String get settingsThemeDialogTitle;

  /// Label for using the gym default theme
  ///
  /// In en, this message translates to:
  /// **'Gym default'**
  String get settingsThemeDefault;

  /// Name of the mint & turquoise theme
  ///
  /// In en, this message translates to:
  /// **'Mint & Turquoise'**
  String get settingsThemeMintTurquoise;

  /// Name of the magenta & violet theme
  ///
  /// In en, this message translates to:
  /// **'Magenta & Violet'**
  String get settingsThemeMagentaViolet;

  /// Name of the red/orange theme
  ///
  /// In en, this message translates to:
  /// **'Red/Orange'**
  String get settingsThemeRedOrange;

  /// Name of the black/white theme
  ///
  /// In en, this message translates to:
  /// **'Black/White'**
  String get settingsThemeBlackWhite;

  /// Name of the azure & sapphire theme
  ///
  /// In en, this message translates to:
  /// **'Azure & Sapphire'**
  String get settingsThemeAzureSapphire;

  /// Name of the amber sunset theme
  ///
  /// In en, this message translates to:
  /// **'Amber Sunset'**
  String get settingsThemeAmberSunset;

  /// Name of the forest & emerald theme
  ///
  /// In en, this message translates to:
  /// **'Forest & Emerald'**
  String get settingsThemeForestEmerald;

  /// Name of the royal plum theme
  ///
  /// In en, this message translates to:
  /// **'Royal Plum'**
  String get settingsThemeRoyalPlum;

  /// Name of the neon lime theme
  ///
  /// In en, this message translates to:
  /// **'Neon Lime'**
  String get settingsThemeNeonLime;

  /// Name of the copper & bronze theme
  ///
  /// In en, this message translates to:
  /// **'Copper & Bronze'**
  String get settingsThemeCopperBronze;

  /// Name of the arctic sky theme
  ///
  /// In en, this message translates to:
  /// **'Arctic Sky'**
  String get settingsThemeArcticSky;

  /// Name of the ember inferno theme
  ///
  /// In en, this message translates to:
  /// **'Ember Inferno'**
  String get settingsThemeEmberInferno;

  /// Name of the cyber grape theme
  ///
  /// In en, this message translates to:
  /// **'Cyber Grape'**
  String get settingsThemeCyberGrape;

  /// Name of the citrus punch theme
  ///
  /// In en, this message translates to:
  /// **'Citrus Punch'**
  String get settingsThemeCitrusPunch;

  /// Error shown when saving the theme failed
  ///
  /// In en, this message translates to:
  /// **'Could not save theme.'**
  String get settingsThemeSaveError;

  /// Settings option to toggle profile visibility
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get settingsOptionPublicProfile;

  /// Settings option to change the username
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get settingsOptionChangeUsername;

  /// Shows the currently selected username
  ///
  /// In en, this message translates to:
  /// **'Current username: {username}'**
  String settingsUsernameCurrent(String username);

  /// Settings option for creatine tracker
  ///
  /// In en, this message translates to:
  /// **'Creatine tracker'**
  String get settingsCreatineTracker;

  /// Enable creatine tracker
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get settingsCreatineEnable;

  /// Disable creatine tracker
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get settingsCreatineDisable;

  /// Status when creatine tracker enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsCreatineEnabled;

  /// Status when creatine tracker disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsCreatineDisabled;

  /// Snackbar when creatine tracker enabled
  ///
  /// In en, this message translates to:
  /// **'Creatine tracker enabled.'**
  String get settingsCreatineSavedEnabled;

  /// Snackbar when creatine tracker disabled
  ///
  /// In en, this message translates to:
  /// **'Creatine tracker disabled.'**
  String get settingsCreatineSavedDisabled;

  /// Label for the imprint placeholder
  ///
  /// In en, this message translates to:
  /// **'Imprint'**
  String get settingsLegalImprint;

  /// Label for the privacy placeholder
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsLegalPrivacy;

  /// Helper text for upcoming legal links
  ///
  /// In en, this message translates to:
  /// **'Link will be added soon.'**
  String get settingsLegalPlaceholderDescription;

  /// Snackbar text for placeholder legal links
  ///
  /// In en, this message translates to:
  /// **'Link to {label} coming soon.'**
  String settingsLegalPlaceholder(String label);

  /// Title for public profile dialog
  ///
  /// In en, this message translates to:
  /// **'Profile visibility'**
  String get publicProfileDialogTitle;

  /// Option label for public profile
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicProfilePublic;

  /// Option label for private profile
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get publicProfilePrivate;

  /// Headline for the machine leaderboard
  ///
  /// In en, this message translates to:
  /// **'King/Queen – {device}'**
  String deviceLeaderboardTitle(String device);

  /// Headline when showing the male leaderboard
  ///
  /// In en, this message translates to:
  /// **'King – {device}'**
  String deviceLeaderboardTitleKing(String device);

  /// Headline when showing the female leaderboard
  ///
  /// In en, this message translates to:
  /// **'Queen – {device}'**
  String deviceLeaderboardTitleQueen(String device);

  /// Info text when leaderboard is not available
  ///
  /// In en, this message translates to:
  /// **'Not available for this device.'**
  String get deviceLeaderboardUnavailable;

  /// Tab label for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get deviceLeaderboardTabToday;

  /// Tab label for week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get deviceLeaderboardTabWeek;

  /// Tab label for month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get deviceLeaderboardTabMonth;

  /// Chip label for all genders
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deviceLeaderboardFilterAll;

  /// Chip label for female filter
  ///
  /// In en, this message translates to:
  /// **'w'**
  String get deviceLeaderboardFilterFemale;

  /// Chip label for male filter
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get deviceLeaderboardFilterMale;

  /// Label for the gender filter group
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get deviceLeaderboardFilterGenderLabel;

  /// Label for the score mode filter group
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get deviceLeaderboardFilterScoreLabel;

  /// Chip label for absolute scores
  ///
  /// In en, this message translates to:
  /// **'Absolute'**
  String get deviceLeaderboardFilterAbsolute;

  /// Chip label for relative scores
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get deviceLeaderboardFilterRelative;

  /// Error message when leaderboard fails
  ///
  /// In en, this message translates to:
  /// **'Could not load leaderboard.'**
  String get deviceLeaderboardError;

  /// Empty state for leaderboard
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get deviceLeaderboardEmpty;

  /// Subtitle showing the relative score
  ///
  /// In en, this message translates to:
  /// **'Relative: {value}×BW'**
  String deviceLeaderboardRelativeValue(String value);

  /// Primary label for relative score
  ///
  /// In en, this message translates to:
  /// **'{value}×BW'**
  String deviceLeaderboardRelativeScore(String value);

  /// Tooltip for the leaderboard icon
  ///
  /// In en, this message translates to:
  /// **'Show King/Queen leaderboard'**
  String get deviceLeaderboardTooltip;

  /// Label for the previous session values shown on a set card
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get setCardPreviousLabel;

  /// Banner text for multi-device
  ///
  /// In en, this message translates to:
  /// **'Multi-device mode: only daily XP and device statistics are counted. No XP per muscle group and no leaderboard update.'**
  String get multiDeviceBannerText;

  /// Dismiss banner
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get multiDeviceBannerOk;

  /// Snackbar text after save
  ///
  /// In en, this message translates to:
  /// **'Session saved. Daily XP and device stats updated.'**
  String get multiDeviceSessionSaved;

  /// No description provided for @storySessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Highlights'**
  String get storySessionTitle;

  /// No description provided for @storySessionDailyXpTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily XP'**
  String get storySessionDailyXpTitle;

  /// No description provided for @storySessionDailyXpValue.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String storySessionDailyXpValue(Object xp);

  /// Label for the gross XP value in the session story dialog banner
  ///
  /// In en, this message translates to:
  /// **'Gross reward'**
  String get storySessionDailyXpGrossLabel;

  /// Label for the net XP change in the session story dialog banner
  ///
  /// In en, this message translates to:
  /// **'XP earned'**
  String get storySessionDailyXpNetLabel;

  /// Hint shown when the XP floor was applied
  ///
  /// In en, this message translates to:
  /// **'Includes minimum balance adjustment'**
  String get storySessionDailyXpFloorAppliedNotice;

  /// Label for the previous XP total in the session story dialog banner
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get storySessionDailyXpPreviousTotalLabel;

  /// Label for the resulting XP total in the session story dialog banner
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get storySessionDailyXpResultingTotalLabel;

  /// Displays the level and XP within that level for the session story summary footer
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {xp} XP'**
  String storySessionDailyXpLevelValue(int level, String xp);

  /// Label for the penalties summary in the session story dialog footer
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get storySessionDailyXpPenaltiesLabel;

  /// No description provided for @storySessionDailyXpBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s XP breakdown'**
  String get storySessionDailyXpBreakdownTitle;

  /// No description provided for @storySessionDailyXpPenaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Penalties applied'**
  String get storySessionDailyXpPenaltyTitle;

  /// No description provided for @storySessionDailyXpComponentBase.
  ///
  /// In en, this message translates to:
  /// **'Base reward'**
  String get storySessionDailyXpComponentBase;

  /// No description provided for @storySessionDailyXpComponentBaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Training day #{day}'**
  String storySessionDailyXpComponentBaseSubtitle(Object day);

  /// No description provided for @storySessionDailyXpComponentComeback.
  ///
  /// In en, this message translates to:
  /// **'Comeback boost'**
  String get storySessionDailyXpComponentComeback;

  /// No description provided for @storySessionDailyXpComponentStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus'**
  String get storySessionDailyXpComponentStreak;

  /// No description provided for @storySessionDailyXpComponentStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{streak, plural, one {#-day streak} other {#-day streak}}'**
  String storySessionDailyXpComponentStreakSubtitle(num streak);

  /// No description provided for @storySessionDailyXpComponentMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone reward'**
  String get storySessionDailyXpComponentMilestone;

  /// No description provided for @storySessionDailyXpComponentMilestoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Milestone day {day}'**
  String storySessionDailyXpComponentMilestoneSubtitle(Object day);

  /// No description provided for @storySessionDailyXpComponentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Additional reward'**
  String get storySessionDailyXpComponentUnknown;

  /// No description provided for @storySessionDailyXpPenaltyStreakBreak.
  ///
  /// In en, this message translates to:
  /// **'Streak break penalty'**
  String get storySessionDailyXpPenaltyStreakBreak;

  /// No description provided for @storySessionDailyXpPenaltyMissedWeek.
  ///
  /// In en, this message translates to:
  /// **'Missed week penalty'**
  String get storySessionDailyXpPenaltyMissedWeek;

  /// No description provided for @storySessionDailyXpPenaltyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get storySessionDailyXpPenaltyGeneric;

  /// No description provided for @storySessionDailyXpPenaltyIdleDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one {# day without training} other {# days without training}}'**
  String storySessionDailyXpPenaltyIdleDays(num days);

  /// No description provided for @storySessionDailyXpPenaltyWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week} without training'**
  String storySessionDailyXpPenaltyWeekLabel(Object week);

  /// Heading above the badges list in the session story dialog
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get storySessionBadgesTitle;

  /// Label for the exercises stat card in the session story dialog
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get storySessionStatsExercisesTitle;

  /// Label for the sets stat card in the session story dialog
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get storySessionStatsSetsTitle;

  /// Label for the duration stat card in the session story dialog
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get storySessionStatsDurationTitle;

  /// Duration text in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String storySessionDurationMinutes(int minutes);

  /// Duration text in hours
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String storySessionDurationHours(int hours);

  /// Duration text in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String storySessionDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @storySessionNewDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'First time on {device}'**
  String storySessionNewDeviceTitle(Object device);

  /// No description provided for @storySessionNewExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'First time: {exercise} on {device}'**
  String storySessionNewExerciseTitle(Object device, Object exercise);

  /// No description provided for @storySessionNewPrTitle.
  ///
  /// In en, this message translates to:
  /// **'New personal record in {name}'**
  String storySessionNewPrTitle(Object name);

  /// Subtitle describing the top set that led to a personal record
  ///
  /// In en, this message translates to:
  /// **'Top PR set: {weight} kg × {reps} reps'**
  String storySessionNewPrSubtitle(String weight, String reps);

  /// Fallback subtitle when only an estimated 1RM is available
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM: {value} kg'**
  String storySessionNewPrFallback(String value);

  /// No description provided for @storySessionButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show training story'**
  String get storySessionButtonTooltip;

  /// No description provided for @storySessionEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No highlights available for this day.'**
  String get storySessionEmptyMessage;

  /// CTA new exercise
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get multiDeviceNewExercise;

  /// Title of exercise list
  ///
  /// In en, this message translates to:
  /// **'Select exercise'**
  String get multiDeviceExerciseListTitle;

  /// Empty state exercise list
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get multiDeviceNoExercises;

  /// Bottom sheet title add
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get multiDeviceAddExerciseTitle;

  /// Bottom sheet title edit
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get multiDeviceEditExerciseTitle;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get multiDeviceNameFieldLabel;

  /// Cancel in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get multiDeviceCancel;

  /// Save in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get multiDeviceSave;

  /// Button to edit exercise
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get multiDeviceEditExerciseButton;

  /// Muscle category chest
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleCategoryChest;

  /// Muscle category shoulders
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscleCategoryShoulders;

  /// Muscle category arms
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get muscleCategoryArms;

  /// Muscle category back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get muscleCategoryBack;

  /// Muscle category core
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscleCategoryCore;

  /// Muscle category legs
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get muscleCategoryLegs;

  /// Hint in search field
  ///
  /// In en, this message translates to:
  /// **'Search exercises...'**
  String get multiDeviceSearchHint;

  /// Dropdown label filter
  ///
  /// In en, this message translates to:
  /// **'Filter by muscle group'**
  String get multiDeviceMuscleGroupFilter;

  /// Dropdown item all
  ///
  /// In en, this message translates to:
  /// **'All muscle groups'**
  String get multiDeviceMuscleGroupFilterAll;

  /// Bottom sheet title add exercise
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get exerciseAddTitle;

  /// Bottom sheet title edit exercise
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get exerciseEditTitle;

  /// Exercise name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exerciseNameLabel;

  /// Header muscle groups
  ///
  /// In en, this message translates to:
  /// **'Muscle groups'**
  String get exerciseMuscleGroupsLabel;

  /// Header for selected muscle groups
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get exerciseSelectedMuscleGroups;

  /// Hint for muscle group search
  ///
  /// In en, this message translates to:
  /// **'Search muscle groups...'**
  String get exerciseSearchMuscleGroupsHint;

  /// Empty state muscle groups
  ///
  /// In en, this message translates to:
  /// **'No muscle groups available'**
  String get exerciseNoMuscleGroups;

  /// Clear all selected muscle groups
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get exerciseEdit_clearAll;

  /// Reset muscle groups to initial selection
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get exerciseEdit_reset;

  /// Discard confirmation title
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get exerciseEdit_discardChangesTitle;

  /// Discard confirmation message
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost.'**
  String get exerciseEdit_discardChangesMessage;

  /// Cancel discard dialog
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get exerciseEdit_keepEditing;

  /// Confirm discard dialog
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get exerciseEdit_discard;

  /// Common cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Common close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Common share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Common save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Title for muscle group admin page
  ///
  /// In en, this message translates to:
  /// **'Manage muscle groups'**
  String get muscleAdminTitle;

  /// Button to clear search and filters
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// Menu to assign muscle groups
  ///
  /// In en, this message translates to:
  /// **'Assign muscle groups'**
  String get assignMuscleGroups;

  /// Menu to clear muscle groups
  ///
  /// In en, this message translates to:
  /// **'Reset muscle groups'**
  String get resetMuscleGroups;

  /// Confirmation message for resetting muscle groups
  ///
  /// In en, this message translates to:
  /// **'Clear primary and secondary muscle groups?'**
  String get resetMuscleGroupsConfirm;

  /// Generic muscle groups title
  ///
  /// In en, this message translates to:
  /// **'Muscle groups'**
  String get muscleGroupTitle;

  /// Primary muscle tab
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get muscleTabsPrimary;

  /// Secondary muscle tab
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get muscleTabsSecondary;

  /// Reset button label
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Empty state primary tab
  ///
  /// In en, this message translates to:
  /// **'No primary muscle groups'**
  String get emptyPrimary;

  /// Empty state secondary tab
  ///
  /// In en, this message translates to:
  /// **'No secondary muscle groups'**
  String get emptySecondary;

  /// Validation when primary missing
  ///
  /// In en, this message translates to:
  /// **'Select a primary muscle group'**
  String get mustSelectPrimary;

  /// Chip label for sorting by name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get filterNameChip;

  /// Chip label for muscle filter
  ///
  /// In en, this message translates to:
  /// **'Muscle'**
  String get filterMuscleChip;

  /// Chip label for recent sort
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get filterRecentChip;

  /// Sort option from A to Z
  ///
  /// In en, this message translates to:
  /// **'A→Z'**
  String get filterSortAz;

  /// Sort option from Z to A
  ///
  /// In en, this message translates to:
  /// **'Z→A'**
  String get filterSortZa;

  /// Semantics for selected muscle group
  ///
  /// In en, this message translates to:
  /// **'Muscle group: {name}, selected'**
  String a11yMgSelected(Object name);

  /// Semantics for unselected muscle group
  ///
  /// In en, this message translates to:
  /// **'Muscle group: {name}, not selected'**
  String a11yMgUnselected(Object name);

  /// Section label for front upper body
  ///
  /// In en, this message translates to:
  /// **'Upper body - front'**
  String get muscleCatUpperFront;

  /// Section label for back upper body
  ///
  /// In en, this message translates to:
  /// **'Upper body - back'**
  String get muscleCatUpperBack;

  /// Section label for core
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscleCatCore;

  /// Section label for lower body
  ///
  /// In en, this message translates to:
  /// **'Lower body'**
  String get muscleCatLower;

  /// No description provided for @friends_title.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends_title;

  /// No description provided for @friends_tab_my_friends.
  ///
  /// In en, this message translates to:
  /// **'My Friends'**
  String get friends_tab_my_friends;

  /// No description provided for @friends_tab_requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friends_tab_requests;

  /// No description provided for @friends_tab_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get friends_tab_search;

  /// No description provided for @friends_action_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friends_action_add;

  /// No description provided for @friends_action_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friends_action_accept;

  /// No description provided for @friends_action_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friends_action_decline;

  /// No description provided for @friends_action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friends_action_cancel;

  /// Action to open a chat with a friend
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get friends_action_chat;

  /// No description provided for @friends_action_training_days.
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get friends_action_training_days;

  /// No description provided for @friends_action_open_profile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get friends_action_open_profile;

  /// No description provided for @friends_action_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friends_action_remove;

  /// No description provided for @friends_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove this contact?'**
  String get friends_remove_title;

  /// No description provided for @friends_remove_message.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to remove {username}?'**
  String friends_remove_message(Object username);

  /// No description provided for @friends_remove_yes.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friends_remove_yes;

  /// No description provided for @friends_remove_no.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friends_remove_no;

  /// No description provided for @friends_snackbar_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get friends_snackbar_sent;

  /// No description provided for @friends_snackbar_accepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get friends_snackbar_accepted;

  /// No description provided for @friends_snackbar_declined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get friends_snackbar_declined;

  /// No description provided for @friends_snackbar_canceled.
  ///
  /// In en, this message translates to:
  /// **'Request canceled'**
  String get friends_snackbar_canceled;

  /// No description provided for @friends_removed_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Contact removed'**
  String get friends_removed_snackbar;

  /// No description provided for @friends_empty_incoming.
  ///
  /// In en, this message translates to:
  /// **'No incoming requests'**
  String get friends_empty_incoming;

  /// No description provided for @friends_empty_outgoing.
  ///
  /// In en, this message translates to:
  /// **'No outgoing requests'**
  String get friends_empty_outgoing;

  /// No description provided for @friends_empty_friends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friends_empty_friends;

  /// No description provided for @friends_empty_search.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get friends_empty_search;

  /// No description provided for @friends_privacy_no_access.
  ///
  /// In en, this message translates to:
  /// **'This user does not share their calendar'**
  String get friends_privacy_no_access;

  /// No description provided for @friends_cta_self.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get friends_cta_self;

  /// No description provided for @friends_cta_friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friends_cta_friend;

  /// No description provided for @friends_cta_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get friends_cta_pending;

  /// No description provided for @friends_action_send.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get friends_action_send;

  /// No description provided for @friends_search_min_chars.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get friends_search_min_chars;

  /// Empty state when a chat has no messages
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get friend_chat_empty;

  /// Hint text for the chat input field
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get friend_chat_input_hint;

  /// Tooltip for sending a chat message
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get friend_chat_send;

  /// Error message when sending a chat message fails
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent.'**
  String get friend_chat_send_error;

  /// Shown when the user must sign in before chatting
  ///
  /// In en, this message translates to:
  /// **'Please sign in to chat.'**
  String get friend_chat_login_required;

  /// Label for bodyweight
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bodyweight;

  /// Abbreviation for bodyweight
  ///
  /// In en, this message translates to:
  /// **'BW'**
  String get bodyweightAbbrev;

  /// Bodyweight plus additional weight
  ///
  /// In en, this message translates to:
  /// **'Bodyweight + {kg} kg'**
  String bodyweightPlus(Object kg);

  /// Tooltip for bodyweight toggle
  ///
  /// In en, this message translates to:
  /// **'Toggle bodyweight'**
  String get bodyweightToggleTooltip;

  /// No description provided for @admin_symbols_title.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get admin_symbols_title;

  /// No description provided for @admin_symbols_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get admin_symbols_search_hint;

  /// No description provided for @user_symbols_title.
  ///
  /// In en, this message translates to:
  /// **'Symbols of {username}'**
  String user_symbols_title(Object username);

  /// No description provided for @inventory_section_title.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory_section_title;

  /// No description provided for @add_symbols_cta.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add_symbols_cta;

  /// No description provided for @gym_library_title.
  ///
  /// In en, this message translates to:
  /// **'Gym Library'**
  String get gym_library_title;

  /// No description provided for @empty_inventory_hint.
  ///
  /// In en, this message translates to:
  /// **'No symbols in inventory yet'**
  String get empty_inventory_hint;

  /// No description provided for @empty_gym_library_hint.
  ///
  /// In en, this message translates to:
  /// **'No additional symbols available'**
  String get empty_gym_library_hint;

  /// No description provided for @no_members_found.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get no_members_found;

  /// No description provided for @saved_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved_snackbar;

  /// No description provided for @assign_failed_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Assignment failed'**
  String get assign_failed_snackbar;

  /// No description provided for @removed_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed_snackbar;

  /// No description provided for @no_permission_symbols.
  ///
  /// In en, this message translates to:
  /// **'No permission to view symbols'**
  String get no_permission_symbols;

  /// Title for the dialog that confirms deleting a training session.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get trainingDetailsDeleteSessionTitle;

  /// Body text explaining that deleting a session removes all associated data.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this session? All related data will be removed.'**
  String get trainingDetailsDeleteSessionMessage;

  /// Confirmation button label for deleting a training session.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get trainingDetailsDeleteSessionConfirm;

  /// Snackbar text shown after a session was deleted.
  ///
  /// In en, this message translates to:
  /// **'Session deleted.'**
  String get trainingDetailsDeleteSessionSuccess;

  /// Snackbar text shown when deleting a session failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the session.'**
  String get trainingDetailsDeleteSessionError;

  /// Tooltip and accessibility label for changing the profile avatar
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get profileChangeAvatar;

  /// Label of the admin tab
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get homeTabAdmin;

  /// Label of the rank tab
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get homeTabRank;

  /// Label of the affiliate tab
  ///
  /// In en, this message translates to:
  /// **'Affiliate'**
  String get homeTabAffiliate;

  /// Label of the plans tab
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get homeTabPlans;

  /// AppBar title of the report screen
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// Title of the feedback card on the report screen
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get reportFeedbackCardTitle;

  /// Subtitle showing open feedback entries
  ///
  /// In en, this message translates to:
  /// **'{count} open entries'**
  String reportFeedbackOpenEntries(int count);

  /// Subtitle shown when there are no open feedback entries
  ///
  /// In en, this message translates to:
  /// **'No open feedback'**
  String get reportFeedbackNoOpenEntries;

  /// Title of the feedback dialog
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackDialogTitle;

  /// Tooltip for the feedback button
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTooltip;

  /// Placeholder text for the feedback input
  ///
  /// In en, this message translates to:
  /// **'Your feedback...'**
  String get feedbackPlaceholder;

  /// Submit button label for feedback
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSubmit;

  /// Snackbar shown after sending feedback
  ///
  /// In en, this message translates to:
  /// **'Feedback sent'**
  String get feedbackSent;

  /// Action title to create a survey
  ///
  /// In en, this message translates to:
  /// **'Create survey'**
  String get reportCreateSurveyTitle;

  /// Action title to open the survey overview
  ///
  /// In en, this message translates to:
  /// **'View surveys'**
  String get reportViewSurveysTitle;

  /// Navigation card title that opens the members report
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get reportMembersButtonTitle;

  /// Subtitle explaining the members navigation card
  ///
  /// In en, this message translates to:
  /// **'View active member numbers'**
  String get reportMembersButtonSubtitle;

  /// Navigation card title that opens the usage report
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get reportUsageButtonTitle;

  /// Subtitle explaining the usage navigation card
  ///
  /// In en, this message translates to:
  /// **'Visualize device usage data'**
  String get reportUsageButtonSubtitle;

  /// Navigation card title that opens the feedback report
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get reportFeedbackButtonTitle;

  /// Subtitle explaining the feedback navigation card
  ///
  /// In en, this message translates to:
  /// **'Review and manage gym feedback'**
  String get reportFeedbackButtonSubtitle;

  /// Navigation card title that opens the surveys report
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get reportSurveysButtonTitle;

  /// Subtitle explaining the surveys navigation card
  ///
  /// In en, this message translates to:
  /// **'Create and monitor member surveys'**
  String get reportSurveysButtonSubtitle;

  /// App bar title for the usage report screen
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get reportUsageTitle;

  /// App bar title for the feedback report screen
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get reportFeedbackTitle;

  /// App bar title for the surveys report screen
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get reportSurveysTitle;

  /// App bar title for the members report screen
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get reportMembersTitle;

  /// App bar action that opens the member usage overview
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get reportMembersUsageButton;

  /// App bar title for the member usage overview
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get reportMembersUsageTitle;

  /// Introductory copy for the member usage overview
  ///
  /// In en, this message translates to:
  /// **'Share of registered members by logged training days.'**
  String get reportMembersUsageDescription;

  /// Hint text when no members with a membership number were found
  ///
  /// In en, this message translates to:
  /// **'No members with a membership number available.'**
  String get reportMembersUsageNoMembers;

  /// Describes a usage bucket with share and counts
  ///
  /// In en, this message translates to:
  /// **'{label}: {percentage}% ({count} of {total})'**
  String reportMembersUsageBucketSummary(Object label, Object percentage, int count, int total);

  /// Column header for the member number in the members report
  ///
  /// In en, this message translates to:
  /// **'Member number'**
  String get reportMembersMemberNumberColumn;

  /// Column header for the role in the members report
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get reportMembersRoleColumn;

  /// Column header for the total number of training days in the members report
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get reportMembersTrainingDaysColumn;

  /// Column header for the created at timestamp in the members report
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get reportMembersCreatedAtColumn;

  /// Message shown when the members report fails to load
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the member list.'**
  String get reportMembersLoadError;

  /// Display value for the member role in the members report
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get reportMembersRoleMember;

  /// Display value for the admin role in the members report
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get reportMembersRoleAdmin;

  /// Hint text for the device usage search field
  ///
  /// In en, this message translates to:
  /// **'Search devices or descriptions'**
  String get reportDeviceFilterHint;

  /// Filter option label for viewing usage data of the last 7 days
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get reportUsageRange7Days;

  /// Filter option label for viewing usage data of the last 30 days
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get reportUsageRange30Days;

  /// Filter option label for viewing usage data of the last 90 days
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get reportUsageRange90Days;

  /// Filter option label for viewing usage data of the last 365 days
  ///
  /// In en, this message translates to:
  /// **'Last 365 days'**
  String get reportUsageRange365Days;

  /// Filter option label for viewing usage data without a time restriction
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get reportUsageRangeAll;

  /// Message shown when there is no usage data
  ///
  /// In en, this message translates to:
  /// **'No usage data available yet'**
  String get reportDeviceUsageEmpty;

  /// Message shown when the device search has no matches
  ///
  /// In en, this message translates to:
  /// **'No devices match your search'**
  String get reportDeviceUsageNoMatches;

  /// Message shown when fetching usage data fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the usage data.'**
  String get reportDeviceUsageError;

  /// Tooltip line with the number of sessions
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String reportDeviceUsageSessions(int count);

  /// Dialog title asking to delete an exercise
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get exerciseDeleteTitle;

  /// Dialog message asking to delete an exercise
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the exercise \"{name}\"?'**
  String exerciseDeleteMessage(Object name);

  /// Generic delete action label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Snackbar text shown when saving fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save.'**
  String get commonSaveError;

  /// Generic fallback label for unknown values
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// Generic title label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// Generic description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// Generic create action label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// Generic submit action label
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// Generic discard action label
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// Message shown when the user has no access
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get commonNoAccess;

  /// Title of the device XP screen
  ///
  /// In en, this message translates to:
  /// **'Device XP'**
  String get xpDeviceTitle;

  /// AppBar title of the XP overview screen
  ///
  /// In en, this message translates to:
  /// **'Muscle group XP overview'**
  String get xpOverviewTitle;

  /// Label for the time range dropdown
  ///
  /// In en, this message translates to:
  /// **'Time range:'**
  String get xpOverviewPeriodLabel;

  /// Dropdown option for the last 7 days
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get xpOverviewPeriodLast7Days;

  /// Dropdown option for the last 30 days
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get xpOverviewPeriodLast30Days;

  /// Dropdown option for total XP
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get xpOverviewPeriodTotal;

  /// Table header for muscle group
  ///
  /// In en, this message translates to:
  /// **'Muscle group'**
  String get xpOverviewTableHeaderMuscleGroup;

  /// Table header for XP
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xpOverviewTableHeaderXp;

  /// Title of the leaderboard dialog
  ///
  /// In en, this message translates to:
  /// **'Leaderboard: {region}'**
  String xpOverviewLeaderboardTitle(Object region);

  /// AppBar title of the challenge admin screen
  ///
  /// In en, this message translates to:
  /// **'Manage challenges'**
  String get challengeAdminTitle;

  /// Error shown when required fields are missing
  ///
  /// In en, this message translates to:
  /// **'Please fill out all fields.'**
  String get challengeAdminErrorFillAllFields;

  /// Label for the required sets field
  ///
  /// In en, this message translates to:
  /// **'Required sets'**
  String get challengeAdminFieldRequiredSets;

  /// Label for the XP reward field
  ///
  /// In en, this message translates to:
  /// **'XP reward'**
  String get challengeAdminFieldXpReward;

  /// Label for the challenge type field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get challengeAdminFieldType;

  /// Tab label for active challenges
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get challengeTabActive;

  /// Tab label for completed challenges
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get challengeTabCompleted;

  /// Message shown when there are no active challenges
  ///
  /// In en, this message translates to:
  /// **'No active challenges'**
  String get challengeEmptyActive;

  /// Message shown when there are no completed challenges
  ///
  /// In en, this message translates to:
  /// **'No completed challenges'**
  String get challengeEmptyCompleted;

  /// XP reward shown in the challenge dialog
  ///
  /// In en, this message translates to:
  /// **'XP: {xp}'**
  String challengeDetailXpReward(int xp);

  /// Device list shown in the challenge dialog
  ///
  /// In en, this message translates to:
  /// **'Devices: {devices}'**
  String challengeDetailDevices(Object devices);

  /// Weekly challenge option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get challengeAdminTypeWeekly;

  /// Monthly challenge option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get challengeAdminTypeMonthly;

  /// Label for the calendar week selector
  ///
  /// In en, this message translates to:
  /// **'Calendar week'**
  String get challengeAdminFieldWeek;

  /// Displayed label for a specific calendar week
  ///
  /// In en, this message translates to:
  /// **'CW {week}'**
  String challengeAdminWeekLabel(int week);

  /// Label for the month selector
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get challengeAdminFieldMonth;

  /// Displayed label for a specific month
  ///
  /// In en, this message translates to:
  /// **'Month {month}'**
  String challengeAdminMonthLabel(int month);

  /// Section title listing devices
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get challengeAdminFieldDevices;

  /// AppBar title when user enters the admin area
  ///
  /// In en, this message translates to:
  /// **'Admin area'**
  String get adminAreaTitle;

  /// Message shown when a user lacks admin rights
  ///
  /// In en, this message translates to:
  /// **'No admin rights'**
  String get adminAreaNoPermission;

  /// AppBar title of the admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboardTitle;

  /// Dialog title when creating a device
  ///
  /// In en, this message translates to:
  /// **'Create device'**
  String get adminDashboardCreateDeviceDialogTitle;

  /// Label asking whether the device has multiple exercises
  ///
  /// In en, this message translates to:
  /// **'Multiple exercises?'**
  String get adminDashboardMultipleExercises;

  /// Label showing the generated device ID
  ///
  /// In en, this message translates to:
  /// **'Device ID: {id}'**
  String adminDashboardDeviceIdLabel(Object id);

  /// Action card title to create a device
  ///
  /// In en, this message translates to:
  /// **'Create device'**
  String get adminDashboardCreateDevice;

  /// Action card title for branding settings
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get adminDashboardBranding;

  /// Snackbar shown after writing an NFC tag
  ///
  /// In en, this message translates to:
  /// **'NFC tag written'**
  String get adminDeviceNfcWritten;

  /// Snackbar shown when writing an NFC tag failed
  ///
  /// In en, this message translates to:
  /// **'Error writing NFC tag: {error}'**
  String adminDeviceNfcWriteError(Object error);

  /// Tooltip for the delete device action
  ///
  /// In en, this message translates to:
  /// **'Delete device'**
  String get deviceDeleteTooltip;

  /// Title for the delete device confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete device?'**
  String get deviceDeleteDialogTitle;

  /// Message shown when confirming device deletion
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the device \"{name}\"?'**
  String deviceDeleteDialogMessage(Object name);

  /// Snackbar shown after a device was deleted
  ///
  /// In en, this message translates to:
  /// **'Device deleted'**
  String get deviceDeleteSuccess;

  /// Tooltip for writing an NFC tag
  ///
  /// In en, this message translates to:
  /// **'Write NFC tag'**
  String get deviceWriteNfcTooltip;

  /// Button label to add selected symbols
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String adminSymbolsAddButton(int count);

  /// Snackbar after symbols were added
  ///
  /// In en, this message translates to:
  /// **'Added {count} symbol(s)'**
  String adminSymbolsAddSuccess(int count);

  /// Snackbar shown when a network request failed
  ///
  /// In en, this message translates to:
  /// **'No connection – please try again later.'**
  String get adminSymbolsRetryLater;

  /// Message shown when no global assets were found
  ///
  /// In en, this message translates to:
  /// **'Manifest contains no global assets'**
  String get adminSymbolsNoGlobalAssets;

  /// Message shown when no assets were found for a specific title
  ///
  /// In en, this message translates to:
  /// **'Manifest contains no {title} assets'**
  String adminSymbolsNoAssetsForTitle(Object title);

  /// Message shown when all global symbols are already assigned
  ///
  /// In en, this message translates to:
  /// **'All global symbols already assigned.'**
  String get adminSymbolsAllGlobalAssigned;

  /// Message shown when all symbols for a specific source are assigned
  ///
  /// In en, this message translates to:
  /// **'All {title} symbols already assigned.'**
  String adminSymbolsAllTitleAssigned(Object title);

  /// Error shown when the selected logo is too large
  ///
  /// In en, this message translates to:
  /// **'Image too large (max 500KB)'**
  String get brandingImageTooLarge;

  /// Error shown when required branding fields are missing
  ///
  /// In en, this message translates to:
  /// **'Please select valid colours and a logo.'**
  String get brandingInvalidConfig;

  /// Button label to pick a branding logo
  ///
  /// In en, this message translates to:
  /// **'Choose logo'**
  String get brandingPickLogo;

  /// Input label for the primary colour
  ///
  /// In en, this message translates to:
  /// **'Primary colour (hex)'**
  String get brandingPrimaryColorLabel;

  /// Input label for the accent colour
  ///
  /// In en, this message translates to:
  /// **'Accent colour (hex)'**
  String get brandingAccentColorLabel;

  /// Snackbar shown when no NFC code was read
  ///
  /// In en, this message translates to:
  /// **'No NFC code detected'**
  String get nfcNoCode;

  /// Snackbar shown when no gym is selected
  ///
  /// In en, this message translates to:
  /// **'No gym selected'**
  String get nfcNoGymSelected;

  /// Snackbar shown when an NFC error occurs
  ///
  /// In en, this message translates to:
  /// **'NFC error: {error}'**
  String nfcError(Object error);

  /// Message shown after submitting a survey
  ///
  /// In en, this message translates to:
  /// **'Thanks for participating!'**
  String get surveyThanks;

  /// Prompt asking the user to choose an option
  ///
  /// In en, this message translates to:
  /// **'Please choose an option:'**
  String get surveySelectOptionPrompt;

  /// Button label to close a survey
  ///
  /// In en, this message translates to:
  /// **'Close survey'**
  String get surveyClose;

  /// Displays vote count with percentage
  ///
  /// In en, this message translates to:
  /// **'{count} votes ({percent}%)'**
  String surveyVotesCountWithPercent(int count, Object percent);

  /// AppBar title for the survey list
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get surveyListTitle;

  /// Tab label for open surveys
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get surveyTabOpen;

  /// Tab label for completed surveys
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get surveyTabClosed;

  /// Message shown when there are no open surveys
  ///
  /// In en, this message translates to:
  /// **'No open surveys'**
  String get surveyEmpty;

  /// Message shown when there are no completed surveys
  ///
  /// In en, this message translates to:
  /// **'No completed surveys'**
  String get surveyEmptyClosed;

  /// Heading shown above survey results
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get surveyResultsTitle;

  /// AppBar title of the gym selection screen
  ///
  /// In en, this message translates to:
  /// **'Select gym'**
  String get selectGymTitle;

  /// Dialog title asking to end the workout
  ///
  /// In en, this message translates to:
  /// **'End workout?'**
  String get sessionStopTitle;

  /// Dialog body asking whether to keep the timer running or discard the tracked duration
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}. Do you want to keep it running or discard the time?'**
  String sessionStopMessage(Object duration);

  /// Semantics label for a digit key
  ///
  /// In en, this message translates to:
  /// **'Key {digit}'**
  String numericKeypadSemanticsDigit(Object digit);

  /// Semantics label for the decimal separator key
  ///
  /// In en, this message translates to:
  /// **'Decimal separator'**
  String get numericKeypadSemanticsDecimal;

  /// Semantics label for the delete key
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get numericKeypadSemanticsDelete;

  /// Semantics label for the next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get numericKeypadSemanticsNext;

  /// Semantics label for the previous button
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get numericKeypadSemanticsPrevious;

  /// Semantics label for the duplicate previous set button
  ///
  /// In en, this message translates to:
  /// **'Duplicate previous set'**
  String get numericKeypadSemanticsDuplicate;

  /// Semantics label for the decrease button
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get numericKeypadSemanticsDecrease;

  /// Semantics label for the increase button
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get numericKeypadSemanticsIncrease;

  /// Semantics label for the hide keyboard button
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get numericKeypadSemanticsHideKeyboard;

  /// Title of the community screen
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// Tab label for today's stats
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get communityTabToday;

  /// Tab label for weekly stats
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get communityTabWeek;

  /// Tab label for monthly stats
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get communityTabMonth;

  /// Headline for the community KPI section
  ///
  /// In en, this message translates to:
  /// **'Community totals'**
  String get communityKpiHeadline;

  /// KPI label for total sessions
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get communityKpiSessions;

  /// KPI label for total exercises
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get communityKpiExercises;

  /// KPI label for total sets
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get communityKpiSets;

  /// KPI label for total repetitions
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get communityKpiReps;

  /// KPI label for total volume
  ///
  /// In en, this message translates to:
  /// **'Volume (kg)'**
  String get communityKpiVolume;

  /// Empty state message when no community stats are available
  ///
  /// In en, this message translates to:
  /// **'No data yet for the selected period.'**
  String get communityEmptyState;

  /// Error message for community stats
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the community stats.'**
  String get communityErrorState;

  /// Retry button label on community screen
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get communityRetryButton;

  /// Heading for the live ticker list
  ///
  /// In en, this message translates to:
  /// **'Live ticker'**
  String get communityFeedTitle;

  /// Message shown when the feed has no entries
  ///
  /// In en, this message translates to:
  /// **'No recent events yet.'**
  String get communityFeedEmpty;

  /// Error message for the live ticker
  ///
  /// In en, this message translates to:
  /// **'Live ticker could not be loaded.'**
  String get communityFeedError;

  /// Headline shown for anonymized training day feed entries
  ///
  /// In en, this message translates to:
  /// **'Training day completed'**
  String get communityFeedTrainingDayHeadline;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
