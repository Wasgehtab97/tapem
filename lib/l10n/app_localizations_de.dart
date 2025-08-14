// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get addSetButton => 'Set hinzufügen';

  @override
  String authErrorGeneric(Object message) {
    return 'Fehler: $message';
  }

  @override
  String get authTitle => 'Anmelden / Registrieren';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get deviceHistoryTooltip => 'Verlauf anzeigen';

  @override
  String get deviceNotFound => 'Gerät nicht gefunden';

  @override
  String get emailFieldLabel => 'E-Mail';

  @override
  String get emailInvalid => 'Bitte gültige E-Mail eingeben.';

  @override
  String trainingDayEndsAt(Object hour) {
    return 'Trainingstag endet um $hour:00';
  }

  @override
  String lateWorkoutsCountPrevDay(Object hour) {
    return 'Späte Workouts zählen zum Vortag (Rollover $hour:00)';
  }

  @override
  String get invalidEmailError => 'Ungültige E-Mail-Adresse.';

  @override
  String get errorPrefix => 'Fehler';

  @override
  String get genericUser => 'Nutzer';

  @override
  String get gymCodeFieldLabel => 'Gym-Code';

  @override
  String get gymCodeHelpLabel => 'Hilfe';

  @override
  String get gymCodeInvalid => 'Ungültiger Gym-Code.';

  @override
  String get gymCodeLockedMessage => 'Zu viele Versuche. Bitte warte 30 Sekunden.';

  @override
  String get gymCodeRequired => 'Gym-Code erforderlich.';

  @override
  String get gymNoDevices => 'Keine Geräte gefunden.';

  @override
  String get gymTitle => 'Gym';

  @override
  String historyTitle(Object deviceId) {
    return 'Verlauf: $deviceId';
  }

  @override
  String get historyChartTitle => 'Workout-Verlauf';

  @override
  String get historyListTitle => 'Vergangene Workouts';

  @override
  String get historyOverviewTitle => 'Übersicht';

  @override
  String get historyWorkouts => 'Workouts';

  @override
  String get historySetsAvg => 'Sets (Ø)';

  @override
  String get historyHeaviest => 'Schwerstes';

  @override
  String get historySessionsChartTitle => 'Sitzungen im Verlauf';

  @override
  String homeWelcome(Object user) {
    return 'Willkommen, $user';
  }

  @override
  String get kgRequired => 'kg?';

  @override
  String get lastEntriesTitle => 'Letzte Einträge';

  @override
  String get languageDialogTitle => 'Sprache wählen';

  @override
  String get loginButton => 'Login';

  @override
  String loginFailed(Object error) {
    return 'Login fehlgeschlagen: $error';
  }

  @override
  String get logoutTooltip => 'Abmelden';

  @override
  String get noteFieldLabel => 'Notiz';

  @override
  String get noteAddTooltip => 'Notiz hinzufügen';

  @override
  String get noteEditTooltip => 'Notiz bearbeiten';

  @override
  String get noteModalTitle => 'Geräte-Notiz';

  @override
  String get noteModalHint => 'Hier Geräte-Einstellungen o. Ä. notieren…';

  @override
  String get noteSaveButton => 'Speichern';

  @override
  String get noteDeleteTooltip => 'Notiz löschen';

  @override
  String get saveSuccess => 'Erfolgreich gespeichert';

  @override
  String get passwordFieldLabel => 'Passwort';

  @override
  String get passwordTooShort => 'Mindestens 6 Zeichen erforderlich.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileTrainingDaysTitle => 'Deine Trainingstage im Jahr';

  @override
  String get repsRequired => 'Wdh?';

  @override
  String get numberInvalid => 'Zahl eingeben';

  @override
  String get intRequired => 'Ganzzahl';

  @override
  String get newSessionTitle => 'Neue Session';

  @override
  String get pleaseCheckInputs => 'Bitte Eingaben prüfen';

  @override
  String get noCompletedSets => 'Keine abgeschlossenen Sätze.';

  @override
  String get todayAlreadySaved => 'Heute bereits gespeichert.';

  @override
  String get setRemoved => 'Satz entfernt';

  @override
  String get undo => 'Rückgängig';

  @override
  String get sessionSaved => 'Session gespeichert';

  @override
  String get setCompleteTooltip => 'Satz abschließen';

  @override
  String get setReopenTooltip => 'Satz wieder öffnen';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get sampleWorkout1 => '12. Mai 2025 – 3×8 @ 80 kg';

  @override
  String get sampleWorkout2 => '10. Mai 2025 – 3×10 @ 75 kg';

  @override
  String get saveButton => 'Speichern';

  @override
  String get settingsIconTooltip => 'Einstellungen';

  @override
  String get tabAffiliate => 'Affiliate';

  @override
  String get tabAdmin => 'Admin';

  @override
  String get tabGym => 'Gym';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabReport => 'Report';

  @override
  String get tableHeaderKg => 'kg';

  @override
  String get tableHeaderNumber => 'Nr.';

  @override
  String get tableHeaderReps => 'Wdh.';

  @override
  String get timerPauseLabel => 'Pause';

  @override
  String get timerStart => 'Start';

  @override
  String get timerStop => 'Stopp';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get timerReset => 'Zurücksetzen';

  @override
  String get timerDuration => 'Dauer';

  @override
  String get timerIncrease => 'Timerdauer erhöhen';

  @override
  String get timerDecrease => 'Timerdauer verringern';

  @override
  String get userNotFound => 'Nutzer nicht gefunden.';

  @override
  String get wrongPassword => 'Falsches Passwort.';

  @override
  String get germanLanguage => 'Deutsch';

  @override
  String get englishLanguage => 'Englisch';

  @override
  String get usernameDialogTitle => 'Nutzernamen wählen';

  @override
  String get usernameFieldLabel => 'Nutzername';

  @override
  String get usernameTaken => 'Dieser Nutzername ist bereits vergeben.';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get passwordResetDialogTitle => 'Passwort zurücksetzen';

  @override
  String get passwordResetHint => 'E-Mail eingeben, um einen Reset-Link zu erhalten.';

  @override
  String get passwordResetSent => 'Passwort-Reset-E-Mail wurde gesendet.';

  @override
  String get resetPasswordTitle => 'Neues Passwort wählen';

  @override
  String get newPasswordFieldLabel => 'Neues Passwort';

  @override
  String get confirmPasswordButton => 'Passwort ändern';

  @override
  String get passwordResetSuccess => 'Passwort geändert.';

  @override
  String get settingsDialogTitle => 'Einstellungen';

  @override
  String get settingsOptionLanguage => 'Sprache';

  @override
  String get settingsOptionPublicProfile => 'Öffentliches Profil';

  @override
  String get publicProfileDialogTitle => 'Profil-Sichtbarkeit';

  @override
  String get publicProfilePublic => 'Öffentlich';

  @override
  String get publicProfilePrivate => 'Privat';

  @override
  String get multiDeviceBannerText => 'Mehrgeräte-Modus: Es werden nur Tages-XP & Gerätestatistiken gezählt. Keine XP pro Muskelgruppe und kein Leaderboard-Update.';

  @override
  String get multiDeviceBannerOk => 'OK';

  @override

  @override

  @override
  String get multiDeviceSessionSaved => 'Session gespeichert. Tages-XP und Stats aktualisiert.';

  @override
  String get multiDeviceNewExercise => 'Übung hinzufügen';

  @override
  String get multiDeviceExerciseListTitle => 'Übung auswählen';

  @override
  String get multiDeviceNoExercises => 'Keine Übungen gefunden';

  @override
  String get multiDeviceAddExerciseTitle => 'Übung hinzufügen';

  @override
  String get multiDeviceEditExerciseTitle => 'Übung bearbeiten';

  @override
  String get multiDeviceNameFieldLabel => 'Name';

  @override
  String get multiDeviceCancel => 'Abbrechen';

  @override
  String get multiDeviceSave => 'Speichern';

  @override
  String get multiDeviceEditExerciseButton => 'Bearbeiten';

  @override
  String get multiDeviceSearchHint => 'Übungen durchsuchen...';

  @override
  String get multiDeviceMuscleGroupFilter => 'Nach Muskelgruppe filtern';

  @override
  String get multiDeviceMuscleGroupFilterAll => 'Alle Muskelgruppen';

  @override
  String get muscleCategoryChest => 'Brust';

  @override
  String get muscleCategoryShoulders => 'Schultern';

  @override
  String get muscleCategoryArms => 'Arme';

  @override
  String get muscleCategoryBack => 'Rücken';

  @override
  String get muscleCategoryCore => 'Rumpf';

  @override
  String get muscleCategoryLegs => 'Beine';

  @override
  String get exerciseAddTitle => 'Übung hinzufügen';

  @override
  String get exerciseEditTitle => 'Übung bearbeiten';

  @override
  String get exerciseNameLabel => 'Name';

  @override
  String get exerciseMuscleGroupsLabel => 'Muskelgruppen';

  @override
  String get exerciseSelectedMuscleGroups => 'Ausgewählt';

  @override
  String get exerciseSearchMuscleGroupsHint => 'Muskelgruppen durchsuchen...';

  @override
  String get exerciseNoMuscleGroups => 'Keine Muskelgruppen verfügbar';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get muscleAdminTitle => 'Muskelgruppen verwalten';

  @override
  String get resetFilters => 'Filter zurücksetzen';

  @override
  String get assignMuscleGroups => 'Muskelgruppen zuweisen';

  @override
  String get resetMuscleGroups => 'Muskelgruppen zurücksetzen';

  @override
  String get resetMuscleGroupsConfirm => 'Primäre und sekundäre Muskelgruppen löschen?';

  @override
  String get muscleGroupTitle => 'Muskelgruppen';

  @override
  String get muscleTabsPrimary => 'Primär';

  @override
  String get muscleTabsSecondary => 'Sekundär';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get emptyPrimary => 'Keine primären Muskelgruppen';

  @override
  String get emptySecondary => 'Keine sekundären Muskelgruppen';

  @override
  String get mustSelectPrimary => 'Bitte primäre Muskelgruppe wählen';

  @override
  String get filterNameChip => 'Name';

  @override
  String get filterMuscleChip => 'Muskel';

  @override
  String a11yMgSelected(Object name) {
    return 'Muskelgruppe: $name, ausgewählt';
  }

  @override
  String a11yMgUnselected(Object name) {
    return 'Muskelgruppe: $name, nicht ausgewählt';
  }

  @override
  String get muscleCatUpperFront => 'Oberkörper – vorne';

  @override
  String get muscleCatUpperBack => 'Oberkörper – hinten';

  @override
  String get muscleCatCore => 'Rumpf';

  @override
  String get muscleCatLower => 'Unterkörper';
}
