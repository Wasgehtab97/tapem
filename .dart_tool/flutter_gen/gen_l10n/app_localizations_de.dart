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
}
