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

  /// Settings option to toggle profile visibility
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get settingsOptionPublicProfile;

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

  /// Hint below header
  ///
  /// In en, this message translates to:
  /// **'In multi-device mode, only daily XP and device stats count.'**

  /// Save button for multi devices
  ///
  /// In en, this message translates to:
  /// **'Save session (no muscle group XP)'**

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

  /// Header muscle groups
  ///
  /// In en, this message translates to:
  /// **'Muscle groups'**

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

  /// Button to change exercise
  ///
  /// In en, this message translates to:
  /// **'Change'**

  /// Button to edit exercise
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get multiDeviceEditExerciseButton;

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

  String get muscleCategoryChest;
  String get muscleCategoryShoulders;
  String get muscleCategoryArms;
  String get muscleCategoryBack;
  String get muscleCategoryCore;
  String get muscleCategoryLegs;

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
