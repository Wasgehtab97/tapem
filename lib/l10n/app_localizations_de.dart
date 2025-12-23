// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Tapem';

  @override
  String get addSetButton => 'Set hinzufügen';

  @override
  String authErrorGeneric(Object message) {
    return 'Fehler: $message';
  }

  @override
  String get authTitle => 'Anmelden / Registrieren';

  @override
  String get gymEntryTitle => 'Gym auswählen';

  @override
  String get gymEntrySubtitle => 'Wähle das Studio, das du nutzen möchtest.';

  @override
  String get gymDropdownLabel => 'Gyms';

  @override
  String get gymLastUsedBadge => 'Zuletzt';

  @override
  String get gymSearchHint => 'Studio suchen';

  @override
  String get gymSearchMinChars => 'Bitte mindestens 3 Buchstaben eingeben.';

  @override
  String get gymSearchEmpty => 'Keine Studios gefunden.';

  @override
  String gymAccessTitle(Object gymName) {
    return 'Willkommen bei $gymName';
  }

  @override
  String get gymAccessSubtitle => 'Melde dich an oder registriere dich, um fortzufahren.';

  @override
  String get gymDemoCta => 'Demo starten';

  @override
  String get gymDemoExitCta => 'Anmelden';

  @override
  String get gymDemoRestrictedMessage => 'Demo-Modus ist nur zum Anschauen. Bitte anmelden, um zu trainieren.';

  @override
  String get gymChangeSelection => 'Gym wechseln';

  @override
  String get gymRegisterMethodTitle => 'Wie möchtest du dich registrieren?';

  @override
  String gymRegisterMethodSubtitle(Object gymName) {
    return 'Wähle die Registrierungsmethode für $gymName.';
  }

  @override
  String get gymRegisterWithNfc => 'Per NFC registrieren';

  @override
  String get gymRegisterWithCode => 'Mit Gymcode registrieren';

  @override
  String gymLoginTitle(Object gymName) {
    return 'Login bei $gymName';
  }

  @override
  String gymRegisterTitle(Object gymName) {
    return 'Registrierung bei $gymName';
  }

  @override
  String get gymNfcHint => 'NFC-Scan folgt im nächsten Schritt. Du kannst den Gymcode vorerst manuell eingeben.';

  @override
  String gymJoinTitle(Object gymName) {
    return '$gymName hinzufügen';
  }

  @override
  String get gymJoinSubtitle => 'Gib den Gymcode ein, um die Mitgliedschaft hinzuzufügen.';

  @override
  String get gymJoinCta => 'Mitgliedschaft hinzufügen';

  @override
  String get gymAddMembershipTitle => 'Studio hinzufügen';

  @override
  String get gymAddMembershipSubtitle => 'Wähle das Studio, das du hinzufügen möchtest.';

  @override
  String get gymMembershipAlreadyAdded => 'Bereits hinzugefügt';

  @override
  String get gymSwitchTitle => 'Studio wechseln';

  @override
  String get gymSwitchSubtitle => 'Wähle das Studio, das du jetzt nutzen möchtest.';

  @override
  String get gymSwitchActiveLabel => 'Aktiv';

  @override
  String get gymAddMembershipCta => 'Weiteres Studio hinzufügen';

  @override
  String get nfcScanTitle => 'NFC scannen';

  @override
  String get nfcScanSubtitle => 'Halte dein Handy an den NFC-Tag im Studio.';

  @override
  String get nfcScanWaiting => 'Warten auf Scan...';

  @override
  String get nfcScanRetry => 'Erneut scannen';

  @override
  String get nfcScanManual => 'Stattdessen Gymcode eingeben';

  @override
  String get nfcUnavailable => 'NFC ist auf diesem Gerät nicht verfügbar.';

  @override
  String get nfcInvalidCode => 'Kein gültiger NFC-Code erkannt.';

  @override
  String get nfcTokenInactive => 'Dieser NFC-Tag ist nicht mehr aktiv.';

  @override
  String get nfcScanFailed => 'NFC-Scan fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loadingLabel => 'Laden...';

  @override
  String get loadingErrorLabel => 'Daten konnten nicht geladen werden.';

  @override
  String get settingsSectionGymAccess => 'Studio-Zugang';

  @override
  String get settingsOptionSwitchGym => 'Studio wechseln';

  @override
  String get settingsOptionSwitchGymSubtitle => 'Aktives Studio ändern oder weitere Mitgliedschaft hinzufügen.';

  @override
  String gymRemoveTitle(Object gymName) {
    return '$gymName entfernen?';
  }

  @override
  String get gymRemoveMessage => 'Diese Mitgliedschaft und der Zugriff werden entfernt.';

  @override
  String get gymRemoveActiveMessage => 'Das ist dein aktives Studio. Danach wirst du auf ein anderes Studio umgeschaltet.';

  @override
  String get gymRemoveCta => 'Entfernen';

  @override
  String get gymRemoveLastBlocked => 'Mindestens eine Mitgliedschaft muss bleiben.';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get commonOk => 'OK';

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
  String get creatineTitle => 'Kreatin';

  @override
  String get creatineTakenToday => 'Heute genommen';

  @override
  String creatineConfirmForDate(Object date) {
    return 'Für $date bestätigen';
  }

  @override
  String get creatineRemoveMarking => 'Markierung entfernen';

  @override
  String creatineSaved(Object date) {
    return 'Kreatin für $date gespeichert';
  }

  @override
  String creatineRemoved(Object date) {
    return 'Kreatin für $date entfernt';
  }

  @override
  String get creatineTakenYesterday => 'Gestern genommen';

  @override
  String get creatineOnlyTodayOrYesterday => 'Nur heute oder gestern möglich.';

  @override
  String get creatineNoCreatine => 'Kein Kreatin?';

  @override
  String get creatineOpenLinkError => 'Link konnte nicht geöffnet werden.';

  @override
  String get signInRequiredError => 'Anmeldung erforderlich.';

  @override
  String get invalidDateError => 'Ungültiges Datum.';

  @override
  String get invalidEmailError => 'Ungültige E-Mail-Adresse.';

  @override
  String get errorPrefix => 'Fehler';

  @override
  String get genericUser => 'Nutzer';

  @override
  String get rankExperience => 'Erfahrung';

  @override
  String get rankDeviceLevel => 'Geräte level';

  @override
  String get rankMuscleLevel => 'Muskel level';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardRankTab => 'Rank';

  @override
  String get leaderboardChallengesTab => 'Challenges';

  @override
  String get leaderboardGymTabLabel => 'Studio';

  @override
  String get leaderboardFriendsTabLabel => 'Freunde';

  @override
  String get leaderboardGymCardTitle => 'Top 10 deines Studios';

  @override
  String get leaderboardFriendsCardTitle => 'Freundesrangliste';

  @override
  String get leaderboardEmptyGym => 'Noch keine Ranglisten-Daten.';

  @override
  String get leaderboardEmptyFriends => 'Noch keine Freunde mit XP.';

  @override
  String get xpInfoTooltip => 'XP-Info';

  @override
  String get xpInfoTitle => 'XP-Info';

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
    return '$xpRemaining XP bis Level $nextLevel';
  }

  @override
  String get xpInfoDetails => 'Details';

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
  String get missingMembershipError => 'Wir konnten keine aktive Mitgliedschaft für dein Konto finden. Bitte kontaktiere dein Gym oder den Support.';

  @override
  String get invalidGymSelectionError => 'Dieses Gym ist nicht mit deinem Konto verknüpft.';

  @override
  String get membershipSyncError => 'Deine Mitgliedschaft konnte nicht synchronisiert werden. Bitte versuche es erneut.';

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
  String get historyAxisDate => 'Datum';

  @override
  String get historyAxisE1rm => 'E1RM';

  @override
  String get historyAxisSessions => 'Sitzungen';

  @override
  String get historyNoData => 'Keine Daten';

  @override
  String get historyE1rmChartSemantics => 'E1RM-Verlauf';

  @override
  String get historySessionsChartSemantics => 'Sitzungen im Verlauf';

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
  String get profileTrainingDaysHeading => 'Trainingstage';

  @override
  String get profileStatsButtonLabel => 'Statistiken';

  @override
  String get profileStatsButtonSubtitle => 'Entdecke deine Fortschritte';

  @override
  String get profileCommunityButtonTitle => 'Community';

  @override
  String get profileCommunityButtonSubtitle => 'Community Meilensteine';

  @override
  String get profileStatsTitle => 'Statistiken';

  @override
  String get profileStatsTotalTrainingDays => 'Trainingstage insgesamt';

  @override
  String get profileStatsAverageTrainingDaysPerWeek => 'Durchschnittliche Trainingstage/Woche';

  @override
  String get profileStatsRestTimerLabel => 'Satztimer';

  @override
  String get profileStatsFavoriteExercise => 'Lieblingsübung';

  @override
  String get profileStatsFavoriteExerciseDialogTitle => 'Top 5 Lieblingsübungen';

  @override
  String get profileStatsFavoriteExerciseFallback => 'Noch keine Sessions';

  @override
  String get profileStatsPowerliftingButton => 'Powerlifting';

  @override
  String get restStatsTitle => 'Satzpausen';

  @override
  String get restStatsHeadline => 'Gesamtdurchschnitt';

  @override
  String get restStatsHeroDescription => 'Durchschnittliche Satzpause über alle Geräte';

  @override
  String get restStatsActualLabel => 'Ø Satzpause';

  @override
  String restStatsSampleCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basierend auf # Sessions',
      one: 'Basierend auf # Session',
    );
    return '$_temp0';
  }

  @override
  String restStatsSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Sätze insgesamt',
      one: '# Satz insgesamt',
    );
    return '$_temp0';
  }

  @override
  String get restStatsErrorMessage => 'Satzpausen konnten nicht geladen werden.';

  @override
  String get restStatsReloadCta => 'Erneut laden';

  @override
  String get restStatsEmptyMessage => 'Noch keine Satzpausen erfasst.';

  @override
  String get repsRequired => 'Wdh?';

  @override
  String get numberInvalid => 'Zahl eingeben';

  @override
  String get intRequired => 'Ganzzahl';

  @override
  String get powerliftingTitle => 'Powerlifting';

  @override
  String get powerliftingAddTooltip => 'Geräte zuordnen';

  @override
  String get powerliftingClearTooltip => 'Board zurücksetzen';

  @override
  String get powerliftingClearConfirmTitle => 'Powerlifting-Board zurücksetzen?';

  @override
  String get powerliftingClearConfirmMessage => 'Dadurch werden alle verknüpften Geräte aus deinem Powerlifting-Board entfernt. Möchtest du fortfahren?';

  @override
  String get powerliftingClearConfirmAction => 'Zurücksetzen';

  @override
  String get powerliftingClearSuccess => 'Powerlifting-Board zurückgesetzt.';

  @override
  String get powerliftingClearError => 'Powerlifting-Board konnte nicht zurückgesetzt werden.';

  @override
  String get powerliftingIntro => 'Verknüpfe alle Geräte mit der jeweiligen Disziplin um deinen PR Fortschritt zu tracken.';

  @override
  String get powerliftingHeaviestTable => 'Schwerste Sätze';

  @override
  String get powerliftingE1rmTable => 'E1RM';

  @override
  String get powerliftingEmptyTitle => 'Baue dein Powerlifting-Board';

  @override
  String get powerliftingEmptyDescription => 'Füge Geräte oder Übungen für Bankdrücken, Kniebeugen und Kreuzheben hinzu, um automatisch deine schwersten Sätze zu sammeln.';

  @override
  String get powerliftingAddButton => 'Powerlifting-Quelle hinzufügen';

  @override
  String get powerliftingDisciplineSheetTitle => 'Disziplin wählen';

  @override
  String powerliftingAssignmentSheetTitle(String discipline) {
    return 'Geräte und Übungen für $discipline auswählen';
  }

  @override
  String powerliftingDeviceSheetTitle(String discipline) {
    return 'Gerät für $discipline wählen';
  }

  @override
  String get powerliftingDeviceIsMultiNote => 'Multi-Gerät – wähle anschließend eine Übung';

  @override
  String powerliftingExerciseSheetTitle(String device) {
    return 'Übung an $device wählen';
  }

  @override
  String get powerliftingNoGymError => 'Wähle zuerst ein Studio, um Powerlifting zu verwalten.';

  @override
  String get powerliftingNoDevicesError => 'Keine Geräte in diesem Studio gefunden.';

  @override
  String powerliftingNoExercisesError(String device) {
    return 'Lege zuerst eine Übung an $device an.';
  }

  @override
  String get powerliftingAddError => 'Powerlifting-Quelle konnte nicht hinzugefügt werden.';

  @override
  String get powerliftingDuplicateError => 'Dieses Gerät bzw. diese Übung ist bereits verknüpft.';

  @override
  String get powerliftingAddSuccess => 'Powerlifting-Quelle hinzugefügt.';

  @override
  String get powerliftingNoRecords => 'Noch keine Bestwerte';

  @override
  String get powerliftingBenchPress => 'Bankdrücken';

  @override
  String get powerliftingSquat => 'Kniebeugen';

  @override
  String get powerliftingDeadlift => 'Kreuzheben';

  @override
  String get dropFillBoth => 'Beide Drop-Felder ausfüllen oder leeren.';

  @override
  String get dropWeightTooHigh => 'Drop KG muss kleiner als Basis sein';

  @override
  String get dropRepsInvalid => 'Drop WDH min 1';

  @override
  String get dropKgFieldLabel => 'Drop KG';

  @override
  String get dropRepsFieldLabel => 'Drop WDH';

  @override
  String get newSessionTitle => 'Neue Session';

  @override
  String get pleaseCheckInputs => 'Bitte Eingaben prüfen';

  @override
  String get noCompletedSets => 'Keine abgeschlossenen Sätze.';

  @override
  String get notAllSetsConfirmed => 'Noch nicht alle Sätze bestätigt.';

  @override
  String get confirmAllSets => 'Alle Bestätigen';

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
  String get resumeSessionButton => 'Zurück zur Session';

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
  String weightFieldLabel(Object unit) {
    return 'Gewicht ($unit)';
  }

  @override
  String bodyweightFieldLabel(Object unit) {
    return 'BW + Zusatz ($unit)';
  }

  @override
  String get bodyweightModeActiveLabel => 'Körpergewichtsmodus aktiv';

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
  String get usernameInvalid => 'Ungültiger Nutzername.';

  @override
  String get usernameHelper => '3–20 Zeichen, Buchstaben, Zahlen, Leerzeichen.';

  @override
  String usernameLowerPreview(Object lower) {
    return 'Klein: $lower';
  }

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
  String get settingsScreenTitle => 'Einstellungen';

  @override
  String get settingsSectionPersonalization => 'Personalisierung';

  @override
  String get settingsSectionHealthTracking => 'Gesundheit & Tracking';

  @override
  String get settingsSectionVisibilityAccount => 'Sichtbarkeit & Konto';

  @override
  String get settingsSectionLegal => 'Rechtliches';

  @override
  String get settingsOptionLanguage => 'Sprache';

  @override
  String get settingsLanguageSystemDefault => 'Systemsprache';

  @override
  String get settingsOptionTheme => 'App-Theme';

  @override
  String get settingsBodyMetrics => 'Körperdaten';

  @override
  String get settingsBodyMetricsDialogTitle => 'Körperdaten';

  @override
  String get settingsGenderLabel => 'Geschlecht';

  @override
  String get settingsGenderNone => 'Nicht gesetzt';

  @override
  String get settingsGenderFemale => 'Weiblich';

  @override
  String get settingsGenderMale => 'Männlich';

  @override
  String get settingsGenderDiverse => 'Divers';

  @override
  String get settingsBodyWeightLabel => 'Körpergewicht (kg)';

  @override
  String get settingsBodyWeightHint => 'z. B. 82,5';

  @override
  String get settingsBodyWeightError => 'Bitte ein gültiges Gewicht eingeben';

  @override
  String get settingsBodyMetricsSaved => 'Körperdaten gespeichert.';

  @override
  String get settingsBodyMetricsSaveError => 'Körperdaten konnten nicht gespeichert werden.';

  @override
  String get settingsBodyMetricsSummaryEmpty => 'Nicht gesetzt';

  @override
  String settingsBodyWeightSummary(String value) {
    return '$value kg';
  }

  @override
  String get settingsThemeDialogTitle => 'App-Theme auswählen';

  @override
  String get settingsThemeDefault => 'Studio-Standard';

  @override
  String get settingsThemeMintTurquoise => 'Mint & Türkis';

  @override
  String get settingsThemeMagentaViolet => 'Magenta & Violett';

  @override
  String get settingsThemeRedOrange => 'Rot/Orange';

  @override
  String get settingsThemeBlackWhite => 'Schwarz/Weiß';

  @override
  String get settingsThemeAzureSapphire => 'Azur & Saphir';

  @override
  String get settingsThemeAmberSunset => 'Bernstein-Sonnenuntergang';

  @override
  String get settingsThemeForestEmerald => 'Wald & Smaragd';

  @override
  String get settingsThemeRoyalPlum => 'Königs-Pflaume';

  @override
  String get settingsThemeNeonLime => 'Neon-Limette';

  @override
  String get settingsThemeCopperBronze => 'Kupfer & Bronze';

  @override
  String get settingsThemeArcticSky => 'Arktischer Himmel';

  @override
  String get settingsThemeEmberInferno => 'Glut-Inferno';

  @override
  String get settingsThemeCyberGrape => 'Cyber-Traube';

  @override
  String get settingsThemeCitrusPunch => 'Zitrus-Punch';

  @override
  String get settingsThemeCyberpunkNeon => 'Cyberpunk Neon';

  @override
  String get settingsThemeAnimeBloom => 'Anime Bloom';

  @override
  String get settingsThemeFlameInferno => 'Feuernation';

  @override
  String get settingsThemeWaterTribe => 'Wasserstamm';

  @override
  String get settingsThemeAirNomads => 'Luftnomaden';

  @override
  String get settingsThemeEarthKingdom => 'Erdkönigreich';

  @override
  String get settingsThemeSaveError => 'Theme konnte nicht gespeichert werden.';

  @override
  String get settingsOptionPublicProfile => 'Öffentliches Profil';

  @override
  String get settingsOptionChangeUsername => 'Nutzername wechseln';

  @override
  String settingsUsernameCurrent(String username) {
    return 'Aktueller Nutzername: $username';
  }

  @override
  String get settingsCreatineTracker => 'Kreatin-Tracker';

  @override
  String get settingsCreatineEnable => 'Aktivieren';

  @override
  String get settingsCreatineDisable => 'Deaktivieren';

  @override
  String get settingsCreatineEnabled => 'Aktiviert';

  @override
  String get settingsCreatineDisabled => 'Deaktiviert';

  @override
  String get settingsCreatineSavedEnabled => 'Kreatin-Tracker aktiviert.';

  @override
  String get settingsCreatineSavedDisabled => 'Kreatin-Tracker deaktiviert.';

  @override
  String get settingsLegalImprint => 'Impressum';

  @override
  String get settingsLegalPrivacy => 'Datenschutz';

  @override
  String get settingsLegalPlaceholderDescription => 'Bald verfügbar.';

  @override
  String settingsLegalPlaceholder(String label) {
    return 'Link zu $label folgt in Kürze.';
  }

  @override
  String get publicProfileDialogTitle => 'Profil-Sichtbarkeit';

  @override
  String get publicProfilePublic => 'Öffentlich';

  @override
  String get publicProfilePrivate => 'Privat';

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
  String get deviceLeaderboardUnavailable => 'Für dieses Gerät nicht verfügbar.';

  @override
  String get deviceLeaderboardTabToday => 'Heute';

  @override
  String get deviceLeaderboardTabWeek => 'Woche';

  @override
  String get deviceLeaderboardTabMonth => 'Monat';

  @override
  String get deviceLeaderboardFilterAll => 'Alle';

  @override
  String get deviceLeaderboardFilterFemale => 'w';

  @override
  String get deviceLeaderboardFilterMale => 'm';

  @override
  String get deviceLeaderboardFilterGenderLabel => 'Geschlecht';

  @override
  String get deviceLeaderboardFilterScoreLabel => 'Wertung';

  @override
  String get deviceLeaderboardFilterAbsolute => 'Absolut';

  @override
  String get deviceLeaderboardFilterRelative => 'Relativ';

  @override
  String get deviceLeaderboardError => 'Leaderboard konnte nicht geladen werden.';

  @override
  String get deviceLeaderboardEmpty => 'Noch keine Einträge.';

  @override
  String deviceLeaderboardRelativeValue(String value) {
    return 'Relativ: $value×Körpergewicht';
  }

  @override
  String deviceLeaderboardRelativeScore(String value) {
    return '$value×KG';
  }

  @override
  String get deviceLeaderboardTooltip => 'King/Queen Leaderboard anzeigen';

  @override
  String get setCardPreviousLabel => 'Vorher';

  @override
  String get multiDeviceBannerText => 'Mehrgeräte-Modus: Es werden nur Tages-XP & Gerätestatistiken gezählt. Keine XP pro Muskelgruppe und kein Leaderboard-Update.';

  @override
  String get multiDeviceBannerOk => 'OK';

  @override
  String get multiDeviceSessionSaved => 'Session gespeichert. Tages-XP und Stats aktualisiert.';

  @override
  String get storySessionTitle => 'Session Highlights';

  @override
  String get storySessionDailyXpTitle => 'Tägliche XP';

  @override
  String storySessionDailyXpValue(Object xp) {
    return '$xp XP';
  }

  @override
  String get storySessionDailyXpGrossLabel => 'Bruttobelohnung';

  @override
  String get storySessionDailyXpNetLabel => 'XP-Erhalt';

  @override
  String get storySessionDailyXpFloorAppliedNotice => 'Beinhaltet Anpassung auf das Mindestguthaben';

  @override
  String get storySessionDailyXpPreviousTotalLabel => 'Vorher';

  @override
  String get storySessionDailyXpResultingTotalLabel => 'Jetzt';

  @override
  String storySessionDailyXpLevelValue(int level, String xp) {
    return 'Level $level · $xp XP';
  }

  @override
  String get storySessionDailyXpPenaltiesLabel => 'Strafen';

  @override
  String get storySessionDailyXpBreakdownTitle => 'Aufschlüsselung deiner XP';

  @override
  String get storySessionDailyXpPenaltyTitle => 'Angewendete Strafen';

  @override
  String get storySessionDailyXpComponentBase => 'Grundbelohnung';

  @override
  String storySessionDailyXpComponentBaseSubtitle(Object day) {
    return 'Trainingstag #$day';
  }

  @override
  String get storySessionDailyXpComponentComeback => 'Comeback-Boost';

  @override
  String get storySessionDailyXpComponentStreak => 'Streak-Bonus';

  @override
  String storySessionDailyXpComponentStreakSubtitle(num streak) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '#-er Streak',
      one: '#-er Streak',
    );
    return '$_temp0';
  }

  @override
  String get storySessionDailyXpComponentMilestone => 'Meilenstein-Bonus';

  @override
  String storySessionDailyXpComponentMilestoneSubtitle(Object day) {
    return 'Meilenstein-Tag $day';
  }

  @override
  String get storySessionDailyXpComponentUnknown => 'Zusätzliche Belohnung';

  @override
  String get storySessionDailyXpPenaltyStreakBreak => 'Strafe für Streak-Abbruch';

  @override
  String get storySessionDailyXpPenaltyMissedWeek => 'Strafe für verpasste Woche';

  @override
  String get storySessionDailyXpPenaltyGeneric => 'Strafe';

  @override
  String storySessionDailyXpPenaltyIdleDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '# trainingsfreie Tage',
      one: '# trainingsfreier Tag',
    );
    return '$_temp0';
  }

  @override
  String storySessionDailyXpPenaltyWeekLabel(Object week) {
    return 'Woche $week ohne Training';
  }

  @override
  String get storySessionBadgesTitle => 'Badges';

  @override
  String get storySessionStatsExercisesTitle => 'Übungen';

  @override
  String get storySessionStatsSetsTitle => 'Sätze';

  @override
  String get storySessionStatsDurationTitle => 'Dauer';

  @override
  String storySessionDurationMinutes(int minutes) {
    return '$minutes Min';
  }

  @override
  String storySessionDurationHours(int hours) {
    return '$hours Std';
  }

  @override
  String storySessionDurationHoursMinutes(int hours, int minutes) {
    return '$hours Std $minutes Min';
  }

  @override
  String storySessionNewDeviceTitle(Object device) {
    return 'Erstes Mal an $device';
  }

  @override
  String storySessionNewExerciseTitle(Object device, Object exercise) {
    return 'Erstes Mal: $exercise an $device';
  }

  @override
  String storySessionNewPrTitle(Object name) {
    return 'Neuer Personal Best in $name';
  }

  @override
  String storySessionNewPrSubtitle(String weight, String reps) {
    return 'Top PR Satz: $weight kg × $reps Wdh';
  }

  @override
  String storySessionNewPrFallback(String value) {
    return 'Geschätztes 1RM: $value kg';
  }

  @override
  String get storySessionButtonTooltip => 'Training-Story anzeigen';

  @override
  String get storySessionEmptyMessage => 'Für diesen Tag gibt es keine Highlights.';

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
  String get multiDeviceSearchHint => 'Übungen durchsuchen...';

  @override
  String get multiDeviceMuscleGroupFilter => 'Nach Muskelgruppe filtern';

  @override
  String get multiDeviceMuscleGroupFilterAll => 'Alle Muskelgruppen';

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
  String get exerciseEdit_clearAll => 'Alle entfernen';

  @override
  String get exerciseEdit_reset => 'Zurücksetzen';

  @override
  String get exerciseEdit_discardChangesTitle => 'Änderungen verwerfen?';

  @override
  String get exerciseEdit_discardChangesMessage => 'Deine Änderungen gehen verloren.';

  @override
  String get exerciseEdit_keepEditing => 'Weiter bearbeiten';

  @override
  String get exerciseEdit_discard => 'Verwerfen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonShare => 'Teilen';

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
  String get filterRecentChip => 'Zuletzt';

  @override
  String get filterSortAz => 'A→Z';

  @override
  String get filterSortZa => 'Z→A';

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

  @override
  String get friends_title => 'Freunde';

  @override
  String get friends_tab_my_friends => 'Meine Freunde';

  @override
  String get friends_tab_requests => 'Anfragen';

  @override
  String get friends_tab_search => 'Suchen';

  @override
  String get friends_action_add => 'Hinzufügen';

  @override
  String get friends_action_accept => 'Annehmen';

  @override
  String get friends_action_decline => 'Ablehnen';

  @override
  String get friends_action_cancel => 'Abbrechen';

  @override
  String get friends_action_chat => 'Chat';

  @override
  String get friends_action_training_days => 'Trainingstage';

  @override
  String get friends_action_open_profile => 'Profil öffnen';

  @override
  String get friends_action_remove => 'Entfernen';

  @override
  String get friends_remove_title => 'Weg mit diesem Kontakt?';

  @override
  String friends_remove_message(Object username) {
    return 'Möchtest du $username wirklich entfernen?';
  }

  @override
  String get friends_remove_yes => 'Ja, entfernen';

  @override
  String get friends_remove_no => 'Nein';

  @override
  String get friends_snackbar_sent => 'Anfrage gesendet';

  @override
  String get friends_snackbar_accepted => 'Anfrage angenommen';

  @override
  String get friends_snackbar_declined => 'Anfrage abgelehnt';

  @override
  String get friends_snackbar_canceled => 'Anfrage abgebrochen';

  @override
  String get friends_removed_snackbar => 'Kontakt entfernt';

  @override
  String get friends_empty_incoming => 'Keine eingehenden Anfragen';

  @override
  String get friends_empty_outgoing => 'Keine ausgehenden Anfragen';

  @override
  String get friends_empty_friends => 'Noch keine Freunde';

  @override
  String get friends_empty_search => 'Keine Nutzer gefunden';

  @override
  String get friends_privacy_no_access => 'Dieser Nutzer teilt seinen Kalender nicht.';

  @override
  String get friends_cta_self => 'Du selbst';

  @override
  String get friends_cta_friend => 'Freund';

  @override
  String get friends_cta_pending => 'Ausstehend';

  @override
  String get friends_action_send => 'Anfrage senden';

  @override
  String get friends_search_min_chars => 'Mindestens 2 Zeichen eingeben';

  @override
  String get friend_chat_empty => 'Noch keine Nachrichten';

  @override
  String get friend_chat_input_hint => 'Schreibe eine Nachricht';

  @override
  String get friend_chat_send => 'Nachricht senden';

  @override
  String get friend_chat_send_error => 'Nachricht konnte nicht gesendet werden.';

  @override
  String get friend_chat_login_required => 'Bitte melde dich an, um zu chatten.';

  @override
  String get bodyweight => 'Körpergewicht';

  @override
  String get bodyweightAbbrev => 'BW';

  @override
  String bodyweightPlus(Object kg) {
    return 'Körpergewicht + $kg kg';
  }

  @override
  String get bodyweightToggleTooltip => 'Körpergewicht umschalten';

  @override
  String get admin_symbols_title => 'Symbole';

  @override
  String get admin_symbols_search_hint => 'Nutzer suchen';

  @override
  String user_symbols_title(Object username) {
    return 'Symbole von $username';
  }

  @override
  String get inventory_section_title => 'Inventar';

  @override
  String get add_symbols_cta => 'Hinzufügen';

  @override
  String get gym_library_title => 'Gym-Bibliothek';

  @override
  String get empty_inventory_hint => 'Noch keine Symbole im Inventar';

  @override
  String get empty_gym_library_hint => 'Keine zusätzlichen Symbole verfügbar';

  @override
  String get no_members_found => 'Keine Mitglieder gefunden';

  @override
  String get saved_snackbar => 'Gespeichert';

  @override
  String get assign_failed_snackbar => 'Zuweisung fehlgeschlagen';

  @override
  String get removed_snackbar => 'Entfernt';

  @override
  String get no_permission_symbols => 'Keine Berechtigung zum Anzeigen der Symbole';

  @override
  String get trainingDetailsDeleteSessionTitle => 'Session löschen';

  @override
  String get trainingDetailsDeleteSessionMessage => 'Möchtest du diese Session wirklich löschen? Alle zugehörigen Daten werden entfernt.';

  @override
  String get trainingDetailsDeleteSessionConfirm => 'Session löschen';

  @override
  String get trainingDetailsDeleteSessionSuccess => 'Session gelöscht.';

  @override
  String get trainingDetailsDeleteSessionError => 'Session konnte nicht gelöscht werden.';

  @override
  String get profileChangeAvatar => 'Profilbild ändern';

  @override
  String get homeTabAdmin => 'Admin';

  @override
  String get homeTabRank => 'Ranking';

  @override
  String get homeTabAffiliate => 'Affiliate';

  @override
  String get homeTabPlans => 'Plan';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportFeedbackCardTitle => 'Feedback';

  @override
  String reportFeedbackOpenEntries(int count) {
    return '$count offene Einträge';
  }

  @override
  String get reportFeedbackNoOpenEntries => 'Kein offenes Feedback';

  @override
  String get feedbackDialogTitle => 'Feedback';

  @override
  String get feedbackTooltip => 'Feedback';

  @override
  String get feedbackPlaceholder => 'Dein Feedback...';

  @override
  String get feedbackSubmit => 'Senden';

  @override
  String get feedbackSent => 'Feedback gesendet';

  @override
  String get reportCreateSurveyTitle => 'Umfrage erstellen';

  @override
  String get reportViewSurveysTitle => 'Umfragen ansehen';

  @override
  String get reportMembersButtonTitle => 'Mitglieder';

  @override
  String get reportMembersButtonSubtitle => 'Aktive Mitgliedsnummern einsehen';

  @override
  String get reportUsageButtonTitle => 'Nutzung';

  @override
  String get reportUsageButtonSubtitle => 'Gerätenutzungsdaten visualisieren';

  @override
  String get reportFeedbackButtonTitle => 'Feedback';

  @override
  String get reportFeedbackButtonSubtitle => 'Feedback verwalten und beantworten';

  @override
  String get reportSurveysButtonTitle => 'Umfragen';

  @override
  String get reportSurveysButtonSubtitle => 'Umfragen erstellen und auswerten';

  @override
  String get reportUsageTitle => 'Nutzung';

  @override
  String get reportFeedbackTitle => 'Feedback';

  @override
  String get reportSurveysTitle => 'Umfragen';

  @override
  String get reportMembersTitle => 'Mitglieder';

  @override
  String get reportMembersUsageButton => 'Nutzung';

  @override
  String get reportMembersUsageTitle => 'Nutzung';

  @override
  String get reportMembersUsageDescription => 'Anteil der registrierten Mitglieder nach dokumentierten Trainingstagen.';

  @override
  String get reportMembersUsageNoMembers => 'Keine Mitglieder mit Mitgliedsnummer vorhanden.';

  @override
  String reportMembersUsageBucketSummary(Object label, Object percentage, int count, int total) {
    return '$label: $percentage% ($count von $total)';
  }

  @override
  String get reportMembersMemberNumberColumn => 'Mitgliedsnummer';

  @override
  String get reportMembersRoleColumn => 'Rolle';

  @override
  String get reportMembersTrainingDaysColumn => 'Trainingstage';

  @override
  String get reportMembersCreatedAtColumn => 'Erstellt am';

  @override
  String get reportMembersLoadError => 'Mitglieder konnten nicht geladen werden.';

  @override
  String get reportMembersRoleMember => 'Mitglied';

  @override
  String get reportMembersRoleAdmin => 'Admin';

  @override
  String get reportMembersRoleCoach => 'Coach';

  @override
  String get reportDeviceFilterHint => 'Geräte oder Beschreibungen suchen';

  @override
  String get reportUsageRange7Days => 'Letzte 7 Tage';

  @override
  String get reportUsageRange30Days => 'Letzte 30 Tage';

  @override
  String get reportUsageRange90Days => 'Letzte 90 Tage';

  @override
  String get reportUsageRange365Days => 'Letzte 365 Tage';

  @override
  String get reportUsageRangeAll => 'Gesamt';

  @override
  String get reportDeviceUsageEmpty => 'Noch keine Nutzungsdaten vorhanden';

  @override
  String get reportDeviceUsageNoMatches => 'Keine Geräte entsprechen deiner Suche';

  @override
  String get reportDeviceUsageError => 'Die Nutzungsdaten konnten nicht geladen werden.';

  @override
  String reportDeviceUsageSessions(int count) {
    return '$count Sessions';
  }

  @override
  String get exerciseDeleteTitle => 'Übung löschen';

  @override
  String exerciseDeleteMessage(Object name) {
    return 'Übung \"$name\" wirklich löschen?';
  }

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSaveError => 'Fehler beim Speichern.';

  @override
  String get commonUnknown => 'Unbekannt';

  @override
  String get commonTitle => 'Titel';

  @override
  String get commonDescription => 'Beschreibung';

  @override
  String get commonCreate => 'Erstellen';

  @override
  String get commonSubmit => 'Absenden';

  @override
  String get commonDiscard => 'Verwerfen';

  @override
  String get commonNoAccess => 'Kein Zugriff';

  @override
  String get xpDeviceTitle => 'Geräte XP';

  @override
  String get xpOverviewTitle => 'XP Übersicht Muskelgruppen';

  @override
  String get xpOverviewPeriodLabel => 'Zeitraum:';

  @override
  String get xpOverviewPeriodLast7Days => '7 Tage';

  @override
  String get xpOverviewPeriodLast30Days => '30 Tage';

  @override
  String get xpOverviewPeriodTotal => 'Gesamt';

  @override
  String get xpOverviewTableHeaderMuscleGroup => 'Muskelgruppe';

  @override
  String get xpOverviewTableHeaderXp => 'XP';

  @override
  String xpOverviewLeaderboardTitle(Object region) {
    return 'Rangliste: $region';
  }

  @override
  String get challengeAdminTitle => 'Challenges verwalten';

  @override
  String get challengeAdminErrorFillAllFields => 'Alle Felder ausfüllen.';

  @override
  String get challengeAdminFieldRequiredSets => 'Benötigte Sätze';

  @override
  String get challengeAdminFieldXpReward => 'XP-Reward';

  @override
  String get challengeAdminFieldType => 'Typ';

  @override
  String get challengeTabActive => 'Aktiv';

  @override
  String get challengeTabCompleted => 'Abgeschlossen';

  @override
  String get challengeEmptyActive => 'Keine aktiven Challenges';

  @override
  String get challengeEmptyCompleted => 'Keine abgeschlossenen Challenges';

  @override
  String challengeDetailXpReward(int xp) {
    return 'XP: $xp';
  }

  @override
  String challengeDetailDevices(Object devices) {
    return 'Geräte: $devices';
  }

  @override
  String get challengeAdminTypeWeekly => 'Wöchentlich';

  @override
  String get challengeAdminTypeMonthly => 'Monatlich';

  @override
  String get challengeAdminFieldWeek => 'Kalenderwoche';

  @override
  String challengeAdminWeekLabel(int week) {
    return 'KW $week';
  }

  @override
  String get challengeAdminFieldMonth => 'Monat';

  @override
  String challengeAdminMonthLabel(int month) {
    return 'Monat $month';
  }

  @override
  String get challengeAdminFieldDevices => 'Geräte';

  @override
  String get adminAreaTitle => 'Adminbereich';

  @override
  String get adminAreaNoPermission => 'Keine Admin-Rechte';

  @override
  String get adminDashboardTitle => 'Admin-Dashboard';

  @override
  String get adminDashboardCreateDeviceDialogTitle => 'Neues Gerät anlegen';

  @override
  String get adminDashboardMultipleExercises => 'Mehrere Übungen?';

  @override
  String adminDashboardDeviceIdLabel(Object id) {
    return 'Geräte-ID: $id';
  }

  @override
  String get adminDashboardCreateDevice => 'Gerät anlegen';

  @override
  String get adminDashboardBranding => 'Branding';

  @override
  String get adminDeviceNfcWritten => 'NFC-Tag geschrieben';

  @override
  String adminDeviceNfcWriteError(Object error) {
    return 'Fehler beim Schreiben: $error';
  }

  @override
  String get deviceDeleteTooltip => 'Gerät löschen';

  @override
  String get deviceDeleteDialogTitle => 'Gerät löschen?';

  @override
  String deviceDeleteDialogMessage(Object name) {
    return 'Soll das Gerät \"$name\" wirklich gelöscht werden?';
  }

  @override
  String get deviceDeleteSuccess => 'Gerät gelöscht';

  @override
  String get deviceWriteNfcTooltip => 'NFC-Tag beschreiben';

  @override
  String adminSymbolsAddButton(int count) {
    return 'Hinzufügen ($count)';
  }

  @override
  String adminSymbolsAddSuccess(int count) {
    return '$count Symbol(e) hinzugefügt';
  }

  @override
  String get adminSymbolsRetryLater => 'Keine Verbindung – später erneut versuchen.';

  @override
  String get adminSymbolsNoGlobalAssets => 'Manifest enthält keine globalen Assets';

  @override
  String adminSymbolsNoAssetsForTitle(Object title) {
    return 'Manifest enthält keine $title-Assets';
  }

  @override
  String get adminSymbolsAllGlobalAssigned => 'Alle globalen Symbole bereits zugewiesen.';

  @override
  String adminSymbolsAllTitleAssigned(Object title) {
    return 'Alle $title-Symbole bereits zugewiesen.';
  }

  @override
  String get brandingImageTooLarge => 'Bild zu groß (max 500KB)';

  @override
  String get brandingInvalidConfig => 'Bitte gültige Farben und Logo wählen';

  @override
  String get brandingPickLogo => 'Logo auswählen';

  @override
  String get brandingPrimaryColorLabel => 'Primärfarbe (hex)';

  @override
  String get brandingAccentColorLabel => 'Akzentfarbe (hex)';

  @override
  String get nfcNoCode => 'Kein NFC-Code erkannt';

  @override
  String get nfcNoGymSelected => 'Kein Gym ausgewählt';

  @override
  String nfcError(Object error) {
    return 'NFC-Fehler: $error';
  }

  @override
  String get surveyThanks => 'Danke für deine Teilnahme!';

  @override
  String get surveySelectOptionPrompt => 'Bitte wähle eine Option:';

  @override
  String get surveyClose => 'Umfrage abschließen';

  @override
  String surveyVotesCountWithPercent(int count, Object percent) {
    return '$count Stimmen ($percent%)';
  }

  @override
  String get surveyListTitle => 'Umfragen';

  @override
  String get surveyTabOpen => 'Offen';

  @override
  String get surveyTabClosed => 'Abgeschlossen';

  @override
  String get surveyEmpty => 'Keine offenen Umfragen';

  @override
  String get surveyEmptyClosed => 'Keine abgeschlossenen Umfragen';

  @override
  String get surveyResultsTitle => 'Ergebnisse';

  @override
  String get selectGymTitle => 'Gym auswählen';

  @override
  String get sessionStopTitle => 'Training beenden?';

  @override
  String sessionStopMessage(Object duration) {
    return 'Dauer: $duration. Möchtest du die Zeit weiterlaufen lassen oder verwerfen?';
  }

  @override
  String numericKeypadSemanticsDigit(Object digit) {
    return 'Taste $digit';
  }

  @override
  String get numericKeypadSemanticsDecimal => 'Dezimaltrennzeichen';

  @override
  String get numericKeypadSemanticsDelete => 'Löschen';

  @override
  String get numericKeypadSemanticsNext => 'Weiter';

  @override
  String get numericKeypadSemanticsPrevious => 'Zurück';

  @override
  String get numericKeypadSemanticsDuplicate => 'Vorherigen Satz duplizieren';

  @override
  String get numericKeypadSemanticsDecrease => 'Verringern';

  @override
  String get numericKeypadSemanticsIncrease => 'Erhöhen';

  @override
  String get numericKeypadSemanticsHideKeyboard => 'Tastatur ausblenden';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityTabToday => 'Heute';

  @override
  String get communityTabWeek => 'Woche';

  @override
  String get communityTabMonth => 'Monat';

  @override
  String get communityKpiHeadline => 'Community-Gesamtwerte';

  @override
  String get communityKpiSessions => 'Einheiten';

  @override
  String get communityKpiExercises => 'Übungen';

  @override
  String get communityKpiSets => 'Sätze';

  @override
  String get communityKpiReps => 'Wiederholungen';

  @override
  String get communityKpiVolume => 'Volumen (kg)';

  @override
  String get communityEmptyState => 'Noch keine Daten im ausgewählten Zeitraum.';

  @override
  String get communityErrorState => 'Community-Daten konnten nicht geladen werden.';

  @override
  String get communityRetryButton => 'Erneut versuchen';

  @override
  String get communityFeedTitle => 'Live-Ticker';

  @override
  String get communityFeedEmpty => 'Noch keine Events.';

  @override
  String get communityFeedError => 'Live-Ticker konnte nicht geladen werden.';

  @override
  String get communityFeedTrainingDayHeadline => 'Trainingstag abgeschlossen';
}
