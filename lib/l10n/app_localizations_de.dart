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
  String get gymMyTitleSingle => 'Mein Gym';

  @override
  String get gymMyTitleMultiple => 'Meine Gyms';

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
  String get historyWorkoutsDesc => 'Anzahl der Workouts, die du für diese Übung absolviert hast.';

  @override
  String get historySetsAvg => 'Sets (Ø)';

  @override
  String get historySetsAvgDesc => 'Durchschnittliche Satzanzahl pro Workout für diese Übung.';

  @override
  String get historyHeaviest => 'Beste';

  @override
  String get historyHeaviestDesc => 'Dein bester Satz in der Form kg × Wdh., basierend auf deinem stärksten Satz.';

  @override
  String get historySessionsChartTitle => 'Sitzungen im Verlauf';

  @override
  String get historyAxisDate => 'Datum';

  @override
  String get historyAxisE1rm => 'E1RM';

  @override
  String get historyE1rmDesc => 'Geschätztes 1-Wiederholungs-Maximum, also dein berechnetes Gewicht für eine Wiederholung.';

  @override
  String get historyAxisSessions => 'Sitzungen';

  @override
  String get historyNoData => 'Keine Daten';

  @override
  String get historyE1rmChartSemantics => 'E1RM-Verlauf';

  @override
  String get historySessionsChartSemantics => 'Sitzungen im Verlauf';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressButtonTitle => 'Progress';

  @override
  String get progressButtonSubtitle => 'Verlauf aller Übungen';

  @override
  String get progressYearLabel => 'Jahr';

  @override
  String get progressEmptyTitle => 'Noch keine Progress-Daten';

  @override
  String get progressEmptySubtitle => 'Trainiere, um deinen Jahresverlauf zu sehen.';

  @override
  String get progressLoadMore => 'Mehr anzeigen';

  @override
  String get progressBackfillAction => 'Progress laden';

  @override
  String get progressBackfillTitle => 'Progress-Daten erstellen';

  @override
  String get progressBackfillBody => 'Deine bisherigen Workouts werden analysiert und der Jahresverlauf erzeugt. Das kann einen Moment dauern und zusätzliche Reads verursachen.';

  @override
  String get progressBackfillConfirm => 'Starten';

  @override
  String get progressBackfillCancel => 'Abbrechen';

  @override
  String progressBackfillDone(Object sessions, Object exercises) {
    return 'Backfill fertig: $sessions Sessions, $exercises Übungen.';
  }

  @override
  String get progressInfoAction => 'So funktioniert’s';

  @override
  String get progressInfoTitle => 'So funktioniert Progress';

  @override
  String get progressInfoBody => 'Charts erscheinen, sobald eine Übung im ausgewählten Jahr mindestens 3 gespeicherte Sessions hat. Trainiere und speichere deine Workouts, um Progress aufzubauen. Nutze den \"Progress-Daten erstellen\" Button oben rechts, um deine Daten zu aktualisieren.';

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
  String get profileStatsNfcScans => 'NFC-Scans';

  @override
  String get profileStatsNfcScansSubtitle => 'insgesamt';

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
  String get settingsThemeMidnightGold => 'Mitternachtsgold';

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
  String get homeTabDeals => 'Deals';

  @override
  String get homeTabPlans => 'Plan';

  @override
  String get homeTabNutrition => 'Ernährung';

  @override
  String get nutritionHomeSubtitle => 'Kalorien, Makros und Tagesziele im Blick.';

  @override
  String get nutritionHomeGoalsTitle => 'Tagesziel setzen';

  @override
  String get nutritionHomeGoalsSubtitle => 'Kalorien und Makroverteilung definieren.';

  @override
  String get nutritionHomeScanTitle => 'Produkt scannen';

  @override
  String get nutritionHomeScanSubtitle => 'Barcode scannen und Eintrag erfassen.';

  @override
  String get nutritionHomeCalendarTitle => 'Jahreskalender';

  @override
  String get nutritionHomeCalendarSubtitle => 'Tage unter/auf/ueber Ziel sehen.';

  @override
  String get nutritionDayTitle => 'Tagesübersicht';

  @override
  String get nutritionTargetLabel => 'Ziel';

  @override
  String get nutritionTotalLabel => 'Gesamt';

  @override
  String get nutritionEmptyEntries => 'Noch keine Eintraege.';

  @override
  String get nutritionEntriesTitle => 'Eintraege';

  @override
  String get nutritionChangeDateCta => 'Datum aendern';

  @override
  String get nutritionScanTitle => 'Produkt scannen';

  @override
  String get nutritionScanHint => 'Barcode im Rahmen ausrichten.';

  @override
  String get nutritionScanManualCta => 'Manuell hinzufuegen';

  @override
  String get nutritionScanCta => 'Produkt scannen';

  @override
  String get nutritionProductTitle => 'Produkt';

  @override
  String nutritionProductBarcode(Object code) {
    return 'Barcode: $code';
  }

  @override
  String get nutritionProductOpenOffCta => 'In Open Food Facts oeffnen';

  @override
  String get nutritionProductRetryCta => 'Suche erneut';

  @override
  String get nutritionBarcodeInvalidHint => 'Barcode wirkt ungueltig. Bitte neu scannen.';

  @override
  String get nutritionProductNotFound => 'Produkt nicht gefunden. Bitte manuell anlegen.';

  @override
  String get nutritionProductManualCta => 'Manuelle Eingabe';

  @override
  String get nutritionProductSaveCta => 'Produkt speichern';

  @override
  String get nutritionProductPer100g => 'Pro 100 g';

  @override
  String get nutritionProductGramsLabel => 'Gramm';

  @override
  String get nutritionProductComputedTitle => 'Berechnet fuer deine Menge';

  @override
  String get nutritionProductAddCta => 'Zum Tag hinzufuegen';

  @override
  String get nutritionAttributionTitle => 'Datenquelle';

  @override
  String get nutritionAttributionBody => 'Produktdaten von Open Food Facts unter ODbL 1.0.';

  @override
  String get nutritionAttributionSourceLink => 'Open Food Facts';

  @override
  String get nutritionAttributionLicenseLink => 'ODbL 1.0';

  @override
  String get nutritionAddEntryCta => 'Eintrag hinzufuegen';

  @override
  String get nutritionEntryTitle => 'Eintrag hinzufügen';

  @override
  String get nutritionEntryNameLabel => 'Name';

  @override
  String get nutritionEntryBarcodeLabel => 'Barcode (optional)';

  @override
  String get nutritionEntryKcalLabel => 'Kalorien';

  @override
  String get nutritionEntryProteinLabel => 'Protein (g)';

  @override
  String get nutritionEntryCarbsLabel => 'Kohlenhydrate (g)';

  @override
  String get nutritionEntryFatLabel => 'Fett (g)';

  @override
  String get nutritionEntryQtyLabel => 'Menge (optional)';

  @override
  String get nutritionEntrySaveCta => 'Eintrag speichern';

  @override
  String get nutritionEntrySaved => 'Eintrag gespeichert.';

  @override
  String get nutritionEntrySaveError => 'Eintrag konnte nicht gespeichert werden.';

  @override
  String get nutritionEntryLookupCta => 'Suchen';

  @override
  String get nutritionEntryLookupFound => 'Produkt geladen.';

  @override
  String get nutritionEntryLookupEmpty => 'Kein Produkt gefunden.';

  @override
  String get nutritionEntryLookupError => 'Suche fehlgeschlagen.';

  @override
  String get nutritionSearchTitle => 'Produkte suchen';

  @override
  String get nutritionSearchHint => 'Open Food Facts durchsuchen';

  @override
  String get nutritionSearchCta => 'Suchen';

  @override
  String get nutritionSearchMinChars => 'Bitte mindestens 2 Zeichen eingeben.';

  @override
  String get nutritionSearchEmpty => 'Keine Produkte gefunden.';

  @override
  String get nutritionSearchError => 'Suche fehlgeschlagen.';

  @override
  String nutritionSearchMacroLine(Object kcal, Object protein, Object carbs, Object fat) {
    return '$kcal kcal | Protein $protein g | Kohlenhydrate $carbs g | Fett $fat g';
  }

  @override
  String get nutritionEditGoalCta => 'Ziele bearbeiten';

  @override
  String get nutritionOpenCalendarCta => 'Kalender oeffnen';

  @override
  String get nutritionGoalsTitle => 'Tagesziele';

  @override
  String get nutritionGoalsIntro => 'Setze dein Kalorienziel und die Makros pro Tag.';

  @override
  String get nutritionGoalsSaveCta => 'Ziele speichern';

  @override
  String get nutritionGoalsSaved => 'Ziele gespeichert.';

  @override
  String get nutritionGoalsSaveError => 'Ziele konnten nicht gespeichert werden.';

  @override
  String get nutritionGoalsCaloriesLabel => 'Kalorien';

  @override
  String get nutritionGoalsProteinLabel => 'Protein (g)';

  @override
  String get nutritionGoalsCarbsLabel => 'Kohlenhydrate (g)';

  @override
  String get nutritionGoalsFatLabel => 'Fett (g)';

  @override
  String get nutritionCalendarTitle => 'Kalender';

  @override
  String get nutritionCalendarIntro => 'Uebersicht, wie oft du dein Ziel im Jahr triffst.';

  @override
  String get nutritionCalendarPlaceholder => 'Kalender-Visualisierung folgt hier.';

  @override
  String get nutritionLegendUnder => 'Unter Ziel';

  @override
  String get nutritionLegendOn => 'Auf Ziel';

  @override
  String get nutritionLegendOver => 'Ueber Ziel';

  @override
  String get nutritionLegendHint => 'Farben zeigen den Tagesstatus.';

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
  String reportCalendarLogCount(Object date, int count) {
    return 'Logs am $date: $count';
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
  String get challengeAdminFieldGoalType => 'Challenge-Art';

  @override
  String get challengeAdminGoalTypeDeviceSets => 'Geräte-Sätze';

  @override
  String get challengeAdminGoalTypeWorkoutFrequency => 'Trainingshäufigkeit';

  @override
  String get challengeAdminFieldType => 'Typ';

  @override
  String get challengeAdminFieldWorkoutCount => 'Trainings pro Zeitraum';

  @override
  String get challengeAdminFieldWorkoutWindow => 'Zeitraum';

  @override
  String get challengeAdminWorkoutWindowOneWeek => '1 Kalenderwoche';

  @override
  String get challengeAdminWorkoutWindowFourWeeks => '4 Kalenderwochen';

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
  String challengeDetailGoalDeviceSets(int count) {
    return 'Ziel: $count Sätze';
  }

  @override
  String challengeDetailGoalWorkoutFrequency(int count, int weeks) {
    return 'Ziel: $count Trainings in $weeks Kalenderwochen';
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
  String get challengeAdminCreateButton => 'Challenge anlegen';

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
  String get adminSymbolsBackfillTooltip => 'usernameLower nachziehen';

  @override
  String adminSymbolsBackfillSuccess(int count) {
    return 'usernameLower aktualisiert: $count';
  }

  @override
  String get adminSymbolsGlobalTitle => 'Global';

  @override
  String get userSymbolsAddTooltip => 'Symbole hinzufügen';

  @override
  String userSymbolsInventoryTitle(Object username) {
    return 'Inventar von $username';
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

  @override
  String get communityCalendarTitle => 'Trainingstage';

  @override
  String get communityCalendarCountOne => '1 Person hat an diesem Tag trainiert.';

  @override
  String communityCalendarCountOther(Object count) {
    return '$count Personen haben an diesem Tag trainiert.';
  }

  @override
  String get ownerWorkspaceTitle => 'Owner Workspace';

  @override
  String ownerWorkspaceActiveGym(Object gymId) {
    return 'Aktives Gym: $gymId';
  }

  @override
  String ownerWorkspaceGeneratedAt(Object timeLabel) {
    return 'Stand: $timeLabel';
  }

  @override
  String get ownerSectionKpiTitle => 'Studio-Überblick';

  @override
  String get ownerSectionKpiSubtitle => 'Die wichtigsten Studio-Signale kompakt auf einen Blick.';

  @override
  String get ownerSectionTasksTitle => 'Heute priorisieren';

  @override
  String get ownerSectionTasksSubtitle => 'Diese Punkte erzeugen direkt operative Wirkung im Studio.';

  @override
  String get ownerSectionQuickActionsTitle => 'Schnellaktionen';

  @override
  String get ownerSectionQuickActionsSubtitle => 'Direkter Zugriff auf alle Owner-Module ohne Routing-Umwege.';

  @override
  String get ownerTasksNone => 'Keine offenen Prioritäten. Studio-Betrieb ist stabil.';

  @override
  String get ownerPriorityHigh => 'hoch';

  @override
  String get ownerPriorityMedium => 'mittel';

  @override
  String get ownerPriorityLow => 'niedrig';

  @override
  String get ownerNoAccessSubtitle => 'Für diesen Bereich sind gymowner- oder admin-Rechte erforderlich.';

  @override
  String get ownerGymContextMissingTitle => 'Gym-Kontext fehlt';

  @override
  String get ownerGymContextMissingSubtitle => 'Wähle zuerst ein aktives Gym aus, damit Owner-Daten geladen werden können.';

  @override
  String get ownerDashboardLoadErrorTitle => 'Owner-Dashboard konnte nicht geladen werden';

  @override
  String ownerDashboardLoadErrorSubtitle(Object error) {
    return 'Bitte aktualisiere die Daten. Fehler: $error';
  }

  @override
  String get ownerNoDataTitle => 'Noch keine Owner-Daten vorhanden';

  @override
  String get ownerNoDataSubtitle => 'Lege zuerst Geräte und erste Studio-Aktionen an, damit das Dashboard verwertbare Signale zeigt.';

  @override
  String get ownerMetricMembersLabel => 'Mitglieder';

  @override
  String get ownerMetricMembersHelper => 'Registrierte Mitglieder im aktiven Gym.';

  @override
  String get ownerMetricDevicesLabel => 'Geräte';

  @override
  String get ownerMetricDevicesHelper => 'Anzahl verfügbarer Trainingsgeräte.';

  @override
  String get ownerMetricOpenFeedbackLabel => 'Offenes Feedback';

  @override
  String get ownerMetricOpenFeedbackHelper => 'Rückmeldungen mit Bearbeitungsbedarf.';

  @override
  String get ownerMetricOpenSurveysLabel => 'Aktive Umfragen';

  @override
  String get ownerMetricOpenSurveysHelper => 'Laufende Umfragen in deinem Gym.';

  @override
  String get ownerMetricActiveChallengesLabel => 'Aktive Challenges';

  @override
  String get ownerMetricActiveChallengesHelper => 'Aktuell laufende Wochen-/Monats-Challenges.';

  @override
  String ownerTaskOpenFeedbackTitle(int count) {
    return '$count offenes Feedback bearbeiten';
  }

  @override
  String get ownerTaskOpenFeedbackSubtitle => 'Unerledigtes Feedback reduziert Servicequalität.';

  @override
  String get ownerTaskPlanChallengeTitle => 'Neue Challenge planen';

  @override
  String get ownerTaskPlanChallengeSubtitle => 'Aktive Challenges steigern Trainingsfrequenz und Bindung.';

  @override
  String get ownerTaskStartSurveyTitle => 'Umfrage starten';

  @override
  String get ownerTaskStartSurveySubtitle => 'Sammle heute aktiv Mitgliedsfeedback mit einer kurzen Umfrage.';

  @override
  String get ownerTaskCreateFirstDeviceTitle => 'Erstes Gerät anlegen';

  @override
  String get ownerTaskCreateFirstDeviceSubtitle => 'Ohne Geräte fehlen zentrale Tracking- und Report-Daten.';

  @override
  String get ownerTaskCheckMembersTitle => 'Mitgliederdaten prüfen';

  @override
  String get ownerTaskCheckMembersSubtitle => 'Wenige Mitglieder im Report können auf unvollständige Daten hinweisen.';

  @override
  String get ownerQuickActionReportSubtitle => 'Nutzung, Mitgliedertrends und Studio-Kennzahlen analysieren.';

  @override
  String get ownerQuickActionMembersSubtitle => 'Mitgliederbasis prüfen und Bereinigung starten.';

  @override
  String get ownerQuickActionDevicesSubtitle => 'Geräte anlegen, bearbeiten und verwalten.';

  @override
  String get ownerQuickActionFeedbackSubtitle => 'Offene Rückmeldungen sichten und erledigen.';

  @override
  String get ownerQuickActionSurveysSubtitle => 'Umfragen erstellen, auswerten und schließen.';

  @override
  String get ownerQuickActionChallengesSubtitle => 'Challenges planen und laufende Aktionen pflegen.';

  @override
  String get ownerQuickActionDealsTitle => 'Deals';

  @override
  String get ownerQuickActionDealsSubtitle => 'Partnerangebote und Promotions steuern.';

  @override
  String get ownerQuickActionAdminSubtitle => 'Alle Admin-Module in einer Übersicht.';

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
  String get reportMembersNoRegisteredMembers => 'Bisher wurden noch keine Mitglieder registriert.';

  @override
  String get reportMembersSummaryTotal => 'Mitglieder';

  @override
  String get reportMembersSummaryActive => 'Aktive Mitglieder';

  @override
  String get reportMembersSummaryInactive => 'Inaktiv';

  @override
  String get reportMembersSummaryAtRisk => 'Gefährdet (hoch)';

  @override
  String get reportMembersSummaryNewMembers => 'Neue Mitglieder';

  @override
  String get reportMembersSummaryLoyal => 'Treue Mitglieder';

  @override
  String get reportMembersSummaryTrainingDays => 'Trainingstage gesamt';

  @override
  String get reportMembersSegmentActions => 'Aktionen für Gruppe';

  @override
  String get reportMembersSegmentAll => 'Alle Mitglieder';

  @override
  String get reportMembersSegmentActive => 'Aktive Mitglieder';

  @override
  String get reportMembersSegmentInactive => 'Inaktive Mitglieder';

  @override
  String get reportMembersSegmentAtRisk => 'Gefährdete Mitglieder';

  @override
  String get reportMembersSegmentNewMembers => 'Neue Mitglieder';

  @override
  String get reportMembersSegmentLoyal => 'Treue Mitglieder';

  @override
  String get reportMembersSegmentNoNumbers => 'Keine Mitgliedsnummern in dieser Gruppe.';

  @override
  String get reportMembersSegmentLargeExportTitle => 'Große Export-Aktion bestätigen';

  @override
  String reportMembersSegmentLargeExportBody(int count) {
    return 'Du exportierst $count Mitgliedsnummern aus \"Alle Mitglieder\". Bitte bestätige, dass dieser Export gewünscht ist.';
  }

  @override
  String get reportMembersSegmentLargeExportConfirm => 'Bestätigen';

  @override
  String reportMembersSegmentActionsFor(Object segmentName) {
    return 'Aktionen für $segmentName';
  }

  @override
  String reportMembersSegmentCount(int count) {
    return '$count Mitglieder in dieser Gruppe.';
  }

  @override
  String get reportMembersSegmentCopy => 'Mitgliedsnummern kopieren';

  @override
  String get reportMembersSegmentCopied => 'Mitgliedsnummern kopiert.';

  @override
  String get reportMembersSegmentShare => 'Mitgliedsnummern teilen';

  @override
  String reportMembersSegmentShareBody(Object segmentName, int count, Object numbers) {
    return '$segmentName ($count Mitglieder)\n\nMitgliedsnummern:\n$numbers';
  }

  @override
  String get reportMembersSegmentShareSubject => 'Mitglieder-Segment aus Report';

  @override
  String get reportMembersSegmentAllShort => 'Alle';

  @override
  String get reportMembersSegmentActiveShort => 'Aktiv';

  @override
  String get reportMembersSegmentInactiveShort => 'Inaktiv';

  @override
  String get reportMembersSegmentAtRiskShort => 'Risiko';

  @override
  String get reportMembersSegmentNewMembersShort => 'Neu';

  @override
  String get reportMembersSegmentLoyalShort => 'Treu';

  @override
  String get reportMembersRiskLow => 'geringes Risiko';

  @override
  String get reportMembersRiskMedium => 'mittleres Risiko';

  @override
  String get reportMembersRiskHigh => 'hohes Risiko';

  @override
  String get reportMembersRiskNewMember => 'neues Mitglied';

  @override
  String get reportMembersAdminOnlyHint => 'Nur Admins dieses Studios können die Trainingstage einsehen.';

  @override
  String get adminNoAccess => 'Kein Zugriff';

  @override
  String get adminRemoveUsersTitle => 'Nutzer entfernen';

  @override
  String get adminSearchUsersHint => 'Nutzer suchen (Name)';

  @override
  String adminMemberSince(Object date) {
    return 'Mitglied seit: $date';
  }

  @override
  String get adminDeleteUserTitle => 'Nutzer und Daten löschen?';

  @override
  String adminDeleteUserMessage(Object name) {
    return 'Der Nutzer \"$name\" und alle zugehörigen Daten in diesem Studio werden unwiderruflich gelöscht.';
  }

  @override
  String get adminDeleteUserAuditHint => 'Diese Aktion wird serverseitig im Admin-Audit protokolliert und kann nicht rückgängig gemacht werden.';

  @override
  String adminDeleteUserSuccess(Object name, Object warning) {
    return 'Nutzer $name$warning gelöscht';
  }

  @override
  String adminDeleteUserError(Object error) {
    return 'Fehler beim Löschen: $error';
  }

  @override
  String brandingSelectedFile(Object filename) {
    return 'Ausgewählte Datei: $filename';
  }

  @override
  String get brandingLogoUrlHint => 'Hinweis: Ohne Cloud Functions bitte stattdessen eine öffentliche Logo-URL eintragen.';

  @override
  String get brandingLogoUrlLabel => 'Logo URL (optional)';

  @override
  String get brandingLogoUrlPlaceholder => 'https://...';

  @override
  String get adminDealsDeleteTitle => 'Deal löschen?';

  @override
  String adminDealsDeleteMessage(Object name) {
    return 'Möchtest du den Deal \"$name\" wirklich löschen?';
  }

  @override
  String get adminDealsTitle => 'Deals verwalten';

  @override
  String adminDealsToggleError(Object error) {
    return 'Fehler beim Aktualisieren des Deal-Status: $error';
  }

  @override
  String adminDealsLoadError(Object error) {
    return 'Fehler beim Laden der Deals: $error';
  }

  @override
  String get adminDealsDeleteAuditHint => 'Diese Änderung wirkt sofort auf die Deal-Ausspielung für Mitglieder.';

  @override
  String get adminDealsDeleted => 'Deal gelöscht.';

  @override
  String get adminDealsCreateSuccess => 'Deal angelegt.';

  @override
  String get adminDealsUpdateSuccess => 'Deal aktualisiert.';

  @override
  String get adminDealsStatusActive => 'Deal ist jetzt aktiv.';

  @override
  String get adminDealsStatusInactive => 'Deal ist jetzt inaktiv.';

  @override
  String get adminDealsRestored => 'Deal wiederhergestellt.';

  @override
  String get adminDealsUndoErrorPrefix => 'Rückgängig fehlgeschlagen';

  @override
  String adminDealsDeleteError(Object error) {
    return 'Fehler beim Löschen des Deals: $error';
  }

  @override
  String get dealFormCategoryDefault => 'Supplements';

  @override
  String get dealFormCategoryLabel => 'Kategorie';

  @override
  String get dealFormRequiredFieldsError => 'Bitte alle Pflichtfelder ausfüllen (Partner, Titel, Code, Link).';

  @override
  String get dealFormInvalidUrlError => 'Shop-Link ist keine gültige URL.';

  @override
  String dealFormSaveError(Object error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String get dealFormTitleNew => 'Neuer Deal';

  @override
  String get dealFormTitleEdit => 'Deal bearbeiten';

  @override
  String get dealFormPartnerLabel => 'Partner Name *';

  @override
  String get dealFormTitleLabel => 'Titel *';

  @override
  String get dealFormCodeLabel => 'Rabattcode *';

  @override
  String get dealFormLinkLabel => 'Shop Link *';

  @override
  String get dealFormImageUrlLabel => 'Bild URL';

  @override
  String get dealFormPartnerLogoLabel => 'Partner-Logo URL';

  @override
  String get dealFormDescriptionLabel => 'Beschreibung';

  @override
  String get dealFormPriorityLabel => 'Priorität';

  @override
  String get dealFormActiveLabel => 'Deal aktiv?';

  @override
  String get adminDeviceEditTitle => 'Gerät bearbeiten';

  @override
  String get adminDeviceNewTitle => 'Neues Gerät anlegen';

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
  String get adminDeviceNameHint => 'z. B. Beinpresse';

  @override
  String get adminDeviceDescLabel => 'Beschreibung';

  @override
  String get adminDeviceDescHint => 'Optional (Model etc.)';

  @override
  String get adminDeviceMultiExerciseLabel => 'Inkludiert mehrere Übungen?';

  @override
  String get adminDeviceMultiExerciseSubtitle => 'Für Kabelzüge oder Racks';

  @override
  String get adminDeviceDeleteAuditHint => 'Gerätestammdaten werden entfernt. Nachgelagerte Auswertungen können davon betroffen sein.';

  @override
  String get adminDashboardChallengesSubtitle => 'Challenges erstellen & verwalten';

  @override
  String get adminDashboardSymbolsSubtitle => 'Benutzer-Symbole & Ränge';

  @override
  String get adminDashboardRemoveUsersTitle => 'Nutzer entfernen';

  @override
  String get adminDashboardRemoveUsersSubtitle => 'Testnutzer & Daten bereinigen';

  @override
  String get adminDashboardDealsTitle => 'Deals verwalten';

  @override
  String get adminDashboardDealsSubtitle => 'Sponsoren & Rabatte pflegen';

  @override
  String get reportTotalSessions => 'Gesamt Sessions';

  @override
  String get reportTopDevice => 'Top Gerät';

  @override
  String reportLogsAtDate(Object date, int count) {
    return 'Logs am $date: $count';
  }

  @override
  String get reportSurveysSubtitle => 'Starte Umfragen und werte das Feedback deiner Mitglieder aus.';

  @override
  String get reportFeedbackSubtitle => 'Verwalte Vorschläge, Beschwerden und Lob deiner Mitglieder.';

  @override
  String reportSurveysStatus(int open, int closed) {
    return 'Aktiv: $open · Abgeschlossen: $closed';
  }

  @override
  String get reportGenericError => 'Ein Fehler ist aufgetreten';

  @override
  String get reportNoDataAvailable => 'Keine Daten verfügbar';

  @override
  String get adminDeviceManufacturerLabel => 'Hersteller';

  @override
  String get adminDeviceMuscleGroupsLabel => 'Muskelgruppen';

  @override
  String get adminDeviceCreateButton => 'Erstellen';

  @override
  String get adminDeviceNameError => 'Bitte gib einen Namen ein.';

  @override
  String get adminDeviceLoadingError => 'Fehler beim Laden';

  @override
  String get adminDeviceNoManufacturers => 'Keine Hersteller aktiviert.';

  @override
  String get adminDeviceManageManufacturers => 'Verwalten';

  @override
  String get adminDeviceSelectManufacturer => 'Hersteller wählen';
}
