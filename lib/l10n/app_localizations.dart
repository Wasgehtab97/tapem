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

  /// KPI label for favourite exercise
  ///
  /// In en, this message translates to:
  /// **'Favourite exercise'**
  String get profileStatsFavoriteExercise;

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

  /// Settings option to change language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsOptionLanguage;

  /// Settings option to change the app theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsOptionTheme;

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

  /// No description provided for @profileChangeAvatar.
  String get profileChangeAvatar;

  /// No description provided for @homeTabAdmin.
  String get homeTabAdmin;

  /// No description provided for @homeTabRank.
  String get homeTabRank;

  /// No description provided for @homeTabAffiliate.
  String get homeTabAffiliate;

  /// No description provided for @homeTabPlans.
  String get homeTabPlans;

  /// No description provided for @reportTitle.
  String get reportTitle;

  /// No description provided for @reportFeedbackCardTitle.
  String get reportFeedbackCardTitle;

  /// No description provided for @reportFeedbackOpenEntries.
  String reportFeedbackOpenEntries(int count);

  /// No description provided for @reportFeedbackNoOpenEntries.
  String get reportFeedbackNoOpenEntries;

  /// No description provided for @feedbackDialogTitle.
  String get feedbackDialogTitle;

  /// No description provided for @feedbackTooltip.
  String get feedbackTooltip;

  /// No description provided for @feedbackPlaceholder.
  String get feedbackPlaceholder;

  /// No description provided for @feedbackSubmit.
  String get feedbackSubmit;

  /// No description provided for @feedbackSent.
  String get feedbackSent;

  /// No description provided for @reportCreateSurveyTitle.
  String get reportCreateSurveyTitle;

  /// No description provided for @reportViewSurveysTitle.
  String get reportViewSurveysTitle;

  /// No description provided for @reportDeviceFilterHint.
  String get reportDeviceFilterHint;

  /// No description provided for @reportDeviceUsageSessions.
  String reportDeviceUsageSessions(int count);

  /// No description provided for @exerciseDeleteTitle.
  String get exerciseDeleteTitle;

  /// No description provided for @exerciseDeleteMessage.
  String exerciseDeleteMessage(Object name);

  /// No description provided for @commonDelete.
  String get commonDelete;

  /// No description provided for @commonSaveError.
  String get commonSaveError;

  /// No description provided for @commonUnknown.
  String get commonUnknown;

  /// No description provided for @commonTitle.
  String get commonTitle;

  /// No description provided for @commonDescription.
  String get commonDescription;

  /// No description provided for @commonCreate.
  String get commonCreate;

  /// No description provided for @commonSubmit.
  String get commonSubmit;

  /// No description provided for @commonDiscard.
  String get commonDiscard;

  /// No description provided for @commonNoAccess.
  String get commonNoAccess;

  /// No description provided for @xpDeviceTitle.
  String get xpDeviceTitle;

  /// No description provided for @xpOverviewTitle.
  String get xpOverviewTitle;

  /// No description provided for @xpOverviewPeriodLabel.
  String get xpOverviewPeriodLabel;

  /// No description provided for @xpOverviewPeriodLast7Days.
  String get xpOverviewPeriodLast7Days;

  /// No description provided for @xpOverviewPeriodLast30Days.
  String get xpOverviewPeriodLast30Days;

  /// No description provided for @xpOverviewPeriodTotal.
  String get xpOverviewPeriodTotal;

  /// No description provided for @xpOverviewTableHeaderMuscleGroup.
  String get xpOverviewTableHeaderMuscleGroup;

  /// No description provided for @xpOverviewTableHeaderXp.
  String get xpOverviewTableHeaderXp;

  /// No description provided for @xpOverviewLeaderboardTitle.
  String xpOverviewLeaderboardTitle(Object region);

  /// No description provided for @challengeAdminTitle.
  String get challengeAdminTitle;

  /// No description provided for @challengeAdminErrorFillAllFields.
  String get challengeAdminErrorFillAllFields;

  /// No description provided for @challengeAdminFieldRequiredSets.
  String get challengeAdminFieldRequiredSets;

  /// No description provided for @challengeAdminFieldXpReward.
  String get challengeAdminFieldXpReward;

  /// No description provided for @challengeAdminFieldType.
  String get challengeAdminFieldType;

  /// No description provided for @challengeTabActive.
  String get challengeTabActive;

  /// No description provided for @challengeTabCompleted.
  String get challengeTabCompleted;

  /// No description provided for @challengeEmptyActive.
  String get challengeEmptyActive;

  /// No description provided for @challengeEmptyCompleted.
  String get challengeEmptyCompleted;

  /// No description provided for @challengeDetailXpReward.
  String challengeDetailXpReward(int xp);

  /// No description provided for @challengeDetailDevices.
  String challengeDetailDevices(Object devices);

  /// No description provided for @challengeAdminTypeWeekly.
  String get challengeAdminTypeWeekly;

  /// No description provided for @challengeAdminTypeMonthly.
  String get challengeAdminTypeMonthly;

  /// No description provided for @challengeAdminFieldWeek.
  String get challengeAdminFieldWeek;

  /// No description provided for @challengeAdminWeekLabel.
  String challengeAdminWeekLabel(int week);

  /// No description provided for @challengeAdminFieldMonth.
  String get challengeAdminFieldMonth;

  /// No description provided for @challengeAdminMonthLabel.
  String challengeAdminMonthLabel(int month);

  /// No description provided for @challengeAdminFieldDevices.
  String get challengeAdminFieldDevices;

  /// No description provided for @adminAreaTitle.
  String get adminAreaTitle;

  /// No description provided for @adminAreaNoPermission.
  String get adminAreaNoPermission;

  /// No description provided for @adminDashboardTitle.
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardCreateDeviceDialogTitle.
  String get adminDashboardCreateDeviceDialogTitle;

  /// No description provided for @adminDashboardMultipleExercises.
  String get adminDashboardMultipleExercises;

  /// No description provided for @adminDashboardDeviceIdLabel.
  String adminDashboardDeviceIdLabel(Object id);

  /// No description provided for @adminDashboardCreateDevice.
  String get adminDashboardCreateDevice;

  /// No description provided for @adminDashboardBranding.
  String get adminDashboardBranding;

  /// No description provided for @adminSymbolsAddButton.
  String adminSymbolsAddButton(int count);

  /// No description provided for @adminSymbolsAddSuccess.
  String adminSymbolsAddSuccess(int count);

  /// No description provided for @adminSymbolsRetryLater.
  String get adminSymbolsRetryLater;

  /// No description provided for @adminSymbolsNoGlobalAssets.
  String get adminSymbolsNoGlobalAssets;

  /// No description provided for @adminSymbolsNoAssetsForTitle.
  String adminSymbolsNoAssetsForTitle(Object title);

  /// No description provided for @adminSymbolsAllGlobalAssigned.
  String get adminSymbolsAllGlobalAssigned;

  /// No description provided for @adminSymbolsAllTitleAssigned.
  String adminSymbolsAllTitleAssigned(Object title);

  /// No description provided for @brandingImageTooLarge.
  String get brandingImageTooLarge;

  /// No description provided for @brandingInvalidConfig.
  String get brandingInvalidConfig;

  /// No description provided for @brandingPickLogo.
  String get brandingPickLogo;

  /// No description provided for @brandingPrimaryColorLabel.
  String get brandingPrimaryColorLabel;

  /// No description provided for @brandingAccentColorLabel.
  String get brandingAccentColorLabel;

  /// No description provided for @nfcNoCode.
  String get nfcNoCode;

  /// No description provided for @nfcNoGymSelected.
  String get nfcNoGymSelected;

  /// No description provided for @nfcError.
  String nfcError(Object error);

  /// No description provided for @surveyThanks.
  String get surveyThanks;

  /// No description provided for @surveySelectOptionPrompt.
  String get surveySelectOptionPrompt;

  /// No description provided for @surveyClose.
  String get surveyClose;

  /// No description provided for @surveyVotesCountWithPercent.
  String surveyVotesCountWithPercent(int count, Object percent);

  /// No description provided for @surveyListTitle.
  String get surveyListTitle;

  /// No description provided for @surveyTabOpen.
  String get surveyTabOpen;

  /// No description provided for @surveyTabClosed.
  String get surveyTabClosed;

  /// No description provided for @surveyEmpty.
  String get surveyEmpty;

  /// No description provided for @surveyEmptyClosed.
  String get surveyEmptyClosed;

  /// No description provided for @surveyResultsTitle.
  String get surveyResultsTitle;

  /// No description provided for @selectGymTitle.
  String get selectGymTitle;

  /// No description provided for @sessionStopTitle.
  String get sessionStopTitle;

  /// No description provided for @sessionStopMessage.
  String sessionStopMessage(Object duration);

  /// No description provided for @numericKeypadSemanticsDigit.
  String numericKeypadSemanticsDigit(Object digit);

  /// No description provided for @numericKeypadSemanticsDecimal.
  String get numericKeypadSemanticsDecimal;

  /// No description provided for @numericKeypadSemanticsDelete.
  String get numericKeypadSemanticsDelete;

  /// No description provided for @numericKeypadSemanticsNext.
  String get numericKeypadSemanticsNext;

  /// No description provided for @numericKeypadSemanticsDecrease.
  String get numericKeypadSemanticsDecrease;

  /// No description provided for @numericKeypadSemanticsIncrease.
  String get numericKeypadSemanticsIncrease;

  /// No description provided for @numericKeypadSemanticsHideKeyboard.
  String get numericKeypadSemanticsHideKeyboard;

  /// No description provided for @adminDeviceNfcWritten.
  String get adminDeviceNfcWritten;

  /// No description provided for @adminDeviceNfcWriteError.
  String adminDeviceNfcWriteError(Object error);

  /// No description provided for @deviceDeleteTooltip.
  String get deviceDeleteTooltip;

  /// No description provided for @deviceDeleteDialogTitle.
  String get deviceDeleteDialogTitle;

  /// No description provided for @deviceDeleteDialogMessage.
  String deviceDeleteDialogMessage(Object name);

  /// No description provided for @deviceDeleteSuccess.
  String get deviceDeleteSuccess;

  /// No description provided for @deviceWriteNfcTooltip.
  String get deviceWriteNfcTooltip;
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
