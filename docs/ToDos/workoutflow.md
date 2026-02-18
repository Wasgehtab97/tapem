## Workout Flow Launch Roadmap (idiotensicher, stabil, wartbar)

Ziel: Der Workout-Flow funktioniert deterministisch und robust fuer alle geforderten Start-/Stop-Szenarien, inkl. Auto-Ende, Tageszuordnung ueber Mitternacht und zuverlaessiger Session-Highlights.

Hinweis zum Status:
- Phase 1 ist abgeschlossen (`6/6` Kernkriterien + Exit-Kriterium).
- Viele offene Checkboxen in Abschnitt 1/3 gehoeren bewusst zu spaeteren Phasen (2-9) und bleiben bis zur jeweiligen End-to-End-Abnahme offen.

Status-Legende:

- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## 0. Dynamischer Fortschritt

Letzte Aktualisierung: 2026-02-14

- Aktuelle Phase: Phase 8 (in Arbeit, inkl. Post-Phase-Hotfixes)
- Aktuelle Artefakte:
  - `docs/ToDos/workoutflow_phase0_pdr.md`
  - `lib/core/services/workout_session_coordinator.dart`
  - `test/core/services/workout_session_coordinator_test.dart`
  - `test/features/device/presentation/workout_flow_phase8_test.dart`
- Naechster Schritt: Phase-8-CI/Smoke-Gate finalisieren und danach Phase 9 (Observability/Rollout-Gates) starten.

Change-Log:

- 2026-02-13: Phase-0-PDR erstellt und in Roadmap verlinkt.
- 2026-02-13: Phase-1-Grundgeruest implementiert (zentraler Coordinator + erste Integration in Profil/NFC/WorkoutDay/Timer-Stop).
- 2026-02-13: Coordinator-API fuer manuelles Save/Stop auf Roadmap-Namen ausgerichtet.
- 2026-02-13: Direkte Timer-Stop-Aufrufe in Profil/Timer-UI auf Coordinator umgestellt; NFC startet Timer nicht mehr sofort.
- 2026-02-13: Globales Inaktivitaets-Auto-Ende angebunden (Coordinator-Timer + persistenter Resume + Auto-Finalize-Handler im Controller-Provider).
- 2026-02-13: Save-All finalisiert nun auch ohne speicherbare Saetze laufende Sessions korrekt (discard/finalize Pfad).
- 2026-02-13: Persistente Completion-Queue + Replay beim App-Start fuer stabile Session-Highlights-Nachholung umgesetzt.
- 2026-02-13: Auto-Finalize-Hardening: Duplicate-Duration-Save im Inactivity-Pfad entfernt, Reentrancy-/Retry-Guard im Coordinator ergaenzt, Empty-Session-Autofinalize im Provider auf Single-Save-Pfad vereinheitlicht.
- 2026-02-13: Starttag-Hardening begonnen: `saveWorkoutSession` verankert `dayKey`/Downstream-Writes (Community, XP, Rest, Last-Session-UI) auf Session-Start statt `now`.
- 2026-02-13: Idempotenz-Hardening im Timer-Service: Reentrancy-Guard fuer parallele `save/discard`-Finalize-Pfade hinzugefuegt.
- 2026-02-13: Session-Meta-Hardening: `anchorDayKey`/`anchorStartTime` als Pflichtfelder im Timer-Finalize und Plan-Meta-Upsert hinterlegt.
- 2026-02-13: Offline-Queue fuer Session-Meta robust gemacht (JSON-sichere Persistenz + defensiver Replay/Normalisierungspfad).
- 2026-02-13: Delete/Reassignment-Pfade priorisieren nun `anchorDayKey` aus Meta vor Legacy-`dayKey`.
- 2026-02-13: Sync-Hardening: Session-Syncjobs tragen nun `anchorDayKey`; Progress-/Delete-Sync verwendet diesen Anchor priorisiert statt Tagesableitung aus Log-Timestamps.
- 2026-02-13: Dispose-Race-Hardening im Duration/Coordinator-Service (post-dispose Guard + Double-Dispose-Vermeidung) umgesetzt; `workout_session_duration_service_test` erfolgreich.
- 2026-02-13: Teststand aktualisiert: `test/core/services/workout_session_duration_service_test.dart` und `test/features/device/presentation/screens/workout_day_screen_test.dart` gruen.
- 2026-02-13: Neue Regressionstests fuer Starttag-Invariante ergänzt (`save` ueber Mitternacht + Legacy-Queue-Replay mit Anchor-Normalisierung) und gruen.
- 2026-02-13: `workout_day_screen_test` auf aktuellen Riverpod-/UI-Flow migriert (Firebase-/Provider-Overrides + stabile Navigation-Checks); Test ist wieder gruen.
- 2026-02-13: Neue Coordinator-Regressionstests fuer first-set-start, Auto-Finalize-Endzeit (`lastSetCompletedAt`) und Restart-Recovery (overdue inactivity) hinzugefuegt und gruen.
- 2026-02-13: Mitternachts-Regression im Coordinator abgedeckt (`start 23:00` + `lastSet 23:40` -> Auto-Finalize mit Endzeit `23:40` und `anchorDayKey` des Starttags).
- 2026-02-13: Double-dispose-Race im `overlayNumericKeypadControllerProvider` behoben (explizites `ref.onDispose(controller.dispose)` entfernt).
- 2026-02-13: Phase-1-Audit abgeschlossen: Business-Running-State in Profil/Gym/ExerciseList/Home auf Coordinator umgestellt; Set-Completion-Startpfad in `DeviceProvider` nutzt nun ausschliesslich den Coordinator (keine direkten Timer-Startpfade mehr).
- 2026-02-13: Phase-2-Finalisierung: Shared `WorkoutEntryOrchestrator` fuer Gym/NFC eingefuehrt (inkl. Duplicate-Guard), NFC-Button/Global-Listener entkoppelt und auf gemeinsame Service-Schicht konsolidiert.
- 2026-02-13: Doppelte Set-Completion-Startorchestrierung entfernt (`DeviceProvider` startet Session nicht mehr separat; Start erfolgt ausschliesslich ueber Coordinator `onSetCompleted`).
- 2026-02-13: Phase-3-Finalisierung: Manueller Save-/Stop-Endflow auf gemeinsamen `WorkoutManualStopFlow`-Finalize-Pfad konsolidiert (WorkoutDay-`Training speichern`, Profil-Stop, Timer-Stop).
- 2026-02-13: Phase-3-Regressionstests ergaenzt (`test/features/device/presentation/workout_manual_stop_flow_test.dart`) und gruen.
- 2026-02-13: Phase-4-Finalisierung: Auto-Finalize-Handler in den globalen Coordinator-Provider verlagert (kein Screen-abhängiges Setup mehr), inkl. Save/Discard-Fallback ueber denselben `saveAllSessions`-Finalize-Pfad.
- 2026-02-13: Highlights-Replay-Hardening: `StorySessionHighlightsListener` triggert Pending-Replay nun auch bei Auth-User-Wechsel (Login nach App-Start).
- 2026-02-13: Phase-4-Regression gruen: `workout_session_coordinator_test`, `workout_session_duration_service_test`, `workout_day_screen_test`, `workout_manual_stop_flow_test`.
- 2026-02-13: Phase-5-Finalisierung: Highlights werden erst nach erfolgreicher Dialog-Ausspielung ge-acked (kein vorzeitiger Queue-Verlust), inkl. Dedupe-Guard fuer Replay+Stream-Doppelereignisse.
- 2026-02-13: Story-Highlights-Hardening testbar gemacht: `GetSessionsForDate` im Listener ueber Provider entkoppelt/overridebar.
- 2026-02-13: Phase-5-Regression gruen: `story_session_highlights_listener_test` (Ack nach Anzeige + Dedupe) plus bestehende Kernregressionen (`workout_session_coordinator_test`, `workout_session_duration_service_test`, `workout_day_screen_test`, `workout_manual_stop_flow_test`).
- 2026-02-13: Phase-6-Finalisierung: Plan-Kontext-Endpfade (`get/set/clear/cancel`) auf expliziten `anchorDayKey` umgestellt (kein implizites `DateTime.now()` mehr fuer Session-Tag in manuellen Endflows).
- 2026-02-13: Mitternachts-Hardening in manuellen Endpfaden: Save/Stop-Flow und Home/WorkoutDay-Planauflosung nutzen nun konsistent Session-Anchor (`anchorStartAt`/`anchorDayKey`), inkl. Regressionstest-Update.
- 2026-02-13: Phase-6-Regression erneut gruen: `flutter analyze` (betroffene Endflow-Dateien) sowie `workout_manual_stop_flow_test`, `workout_day_screen_test`, `workout_session_coordinator_test`, `workout_session_duration_service_test`.
- 2026-02-13: Phase-7-Sync-Refactor: Session-Sync in klar getrennte Create/Delete-Pfade entkoppelt; pro Session `session_sync_marker` als Idempotenz-Guard eingefuehrt (Retry-safe, keine Doppel-Apply bei Wiederholung).
- 2026-02-13: Phase-7-Endflow-Hardening: Einheitliche Workout-Fehlercodes + standardisierte User-Messages fuer manuelle Finish-/Stop-Fehlerpfade umgesetzt.
- 2026-02-13: Neue Sync-Regressionstests hinzugefuegt und gruen (`test/core/sync/sync_service_test.dart`: Create-Dedupe + Delete-Dedupe).
- 2026-02-13: Phase-8-Integrationsmatrix erweitert: neue End-to-End-nahe Tests fuer Profil/Gym/NFC-Startpfade inkl. Save/Stop + Highlights (`test/features/device/presentation/workout_flow_phase8_test.dart`).
- 2026-02-13: Phase-8-Matrix-Hardening: Restart-Recovery, Pending-Highlights-Replay und Offline-Sync-Dedupe als gruen verifiziert (`workout_session_coordinator_test`, `story_session_highlights_listener_test`, `sync_service_test`).
- 2026-02-13: Phase-8-Nichtfunktional ergänzt: Performance-Smoketest fuer Finalize+Highlights, Soak-Test ueber 60 Session-Zyklen, Recovery-Tests fuer korrupten Timer-/Coordinator-State (`workout_flow_phase8_test`, `workout_session_duration_service_test`, `workout_session_coordinator_test`).
- 2026-02-13: Post-Phase-Hotfix: Profil-Play navigiert deterministisch via Root-Navigator auf Gym (`/home`, Index 0), Planstart deterministisch auf Workout (`/home`, Index 2), Finish-Flow-Snackbar nach Navigation context-sicher entkoppelt (kein deactivated-context Zugriff), manueller Save erzwingt defensiv `Coordinator.isRunning=false` falls Finalize-Randfall auftrat; Regression via `workout_finish_flow_test`, `workout_manual_stop_flow_test`, `workout_flow_phase8_test` erweitert und gruen.
- 2026-02-13: Post-Phase-Hotfix 2: Dispose-Race im `WorkoutSessionCoordinator` gehaertet (asynchrone Start/Set/Finalize-Pfade mit post-await dispose-Guards + safe-notify), Profil-Start liest Coordinator unmittelbar vor Start neu (kein stale/disposed Ref), manueller Save finalisiert idempotent immer auch auf dem UI-gebundenen Coordinator; Regression via `workout_session_coordinator_test` erweitert.
- 2026-02-13: Post-Phase-Hotfix 3: Save-Finalize nutzt nun den live Coordinator aus dem Riverpod-Container (nicht nur uebergebene Referenz) und synchronisiert vor Finalize explizit den aktiven User/Gym-Kontext; zusaetzlicher Regressionstest im Manual-Stop-Flow.
- 2026-02-13: Post-Phase-Hotfix 4: Stale `onSetCompleted`-Race nach manuellem Finalize abgefangen (late Set-Events mit `completedAt <= finalizedAt` werden ignoriert, koennen Session nicht mehr reaktivieren); neue Regressionstests fuer "stale event ignored" und "new event starts fresh session" in `workout_session_coordinator_test` gruen.
- 2026-02-13: Post-Phase-Hotfix 5: Idle-Start nach Finalize gehaertet (Set-Events koennen abgeschlossene Session nicht mehr reaktivieren ohne expliziten neuen Add-Intent via Gym/NFC); zusaetzlich WorkoutDay-Init re-armt Coordinator nicht mehr bei bereits existierender Session. Regressionen (`workout_session_coordinator_test`, `workout_day_screen_test`, `workout_manual_stop_flow_test`, `workout_flow_phase8_test`) gruen.
- 2026-02-13: Post-Phase-Hotfix 6: Stale-Running-Recovery im Profil-Play (`isRunning=true` aber Timer idle blockiert neuen Start nicht mehr), plus Fix fuer rekursiven Auto-Finalize-Loop ohne Handler (kein StackOverflow bei overdue Running-State). Regressionen aktualisiert und gruen.
- 2026-02-13: Post-Phase-Hotfix 7: UI-Hardening fuer Aktivzustand (Profil-Orb und Workout-Tab nutzen nun `Coordinator && Timer` als Aktivsignal; Workout-Tab wird zusaetzlich bei vorhandenen Sessions angezeigt), plus stale-marker-heal im Profil-Startpfad. Regression-Suite erneut gruen.
- 2026-02-13: Post-Phase-Hotfix 8: Coordinator lauscht nun auf App-Lifecycle-Resume und evaluiert Inaktivitaet sofort nach App-Rueckkehr (wichtig fuer Nacht-/Background-Faelle mit pausierten Dart-Timern); neuer Regressionstest `resume lifecycle triggers overdue inactivity auto-finalize` gruen.
- 2026-02-14: Post-Phase-Hotfix 9: Recovery fuer inkonsistenten Restart-Status ergänzt (`Coordinator` uebernimmt bei fehlendem `lastSetCompletedAt` den persisted `DurationService.lastActivityTime` als Fallback), damit ueberfaellige Sessions beim naechsten Resume deterministisch auto-finalized werden; neuer Regressionstest `recovery uses duration last activity when coordinator state misses last set` gruen.
- 2026-02-14: Post-Phase-Hotfix 10: Set-Completion-Robustheit im `DeviceProvider` gehaertet (stale/missing Coordinator-Referenz wird aus globalem Container erneuert und erneut aufgerufen; letzter Fallback schreibt `DurationService.lastActivity`, damit Resume-Recovery dennoch greifen kann).
- 2026-02-14: Post-Phase-Hotfix 11: Inaktivitaets-Schwelle zentral konfigurierbar gemacht (`WORKOUT_INACTIVITY_MINUTES`), auf allen relevanten Pfaden vereinheitlicht (Coordinator, Duration-Service, Device-Draft-Autofinalize). Dev-Emulator-Target `ios-emu-dev-d` setzt testweise 5 Minuten per `dart-define`; Rueckstellung auf 60 Minuten per Make-Variable ohne Codeaenderung.
- 2026-02-14: Post-Phase-Hotfix 12: Inaktivitaets-Recovery weiter gehaertet: Coordinator synchronisiert Running-State nun defensiv aus dem `DurationService` (inkl. missing-`lastSet`-Recovery) und evaluiert Timeout auch aus diesem Self-Heal-Pfad; Set-Completion pusht vor `onSetCompleted` explizit den aktiven User/Gym-Kontext in den Coordinator, um Context-Drift nach Lifecycle-/Provider-Wechseln zu vermeiden.
- 2026-02-14: Post-Phase-Hotfix 13: Finalize-/Retry-Hardening im Coordinator: Finalize beendet lokalen Running-State auch ohne aktiven Auth-Kontext, Re-Adopt aus `DurationService` ist nach gesetztem Finalize-Marker blockiert, und Auto-Finalize-Versuche werden fuer denselben `lastSet` dedupliziert (kein unmittelbarer Doppel-Trigger innerhalb des Retry-Fensters).
- 2026-02-14: Post-Phase-Hotfix 14: Set-Completion-Dispatch im `DeviceProvider` gegen stale/disposed Coordinator gehaertet (immer frischer Resolver-Lookup fuer Satzabhaekungen, disposed-Instanzen werden verworfen, fehlender User/Gym-Kontext wird explizit geloggt), damit `onSetCompleted` deterministisch beim lebenden Coordinator ankommt.
- 2026-02-14: Konsolidierungs-Refactor: `WorkoutSessionCoordinator` auf Single-Timer-Stateflow reduziert (ohne Running-Adoption/Retry-Kaskaden), `WorkoutSessionDurationService` von redundanter Auto-Stop-Logik befreit (nur noch Zeitquelle + Persistenz), `DeviceProvider` dispatcht Set-Completion nun serialisiert ueber den injizierten Coordinator (kein Container-Refresh), und `workout_day_controller_provider` re-attached Session-Services bei Provider-Wechseln fuer stale-safe Referenzen.

Phase-1 Launch-Ready Audit (schrittweise):

1. Start/Stop/AutoStop-API zentral im `WorkoutSessionCoordinator` verifiziert (`startFromProfilePlay`, `onExerciseAddedFromGymOrNfc`, `onSetCompleted`, `finishManually...`, `finishAutomaticallyAfterInactivity`).
2. Alle UI-Einstiegspunkte auf Coordinator-Calls geprueft und konsolidiert (Profil, Gym, ExerciseList, WorkoutDay, NFC, Timer-Stop).
3. Direkte Timer-Startorchestrierung aus `DeviceProvider` entfernt; Satz-Completion startet/aktualisiert nur noch ueber Coordinator.
4. Business-`isRunning`-Entscheidungen von Duration-Service auf Coordinator umgestellt (Profil/Gym/ExerciseList/Home).
5. Persistenz-Invarianten fuer `anchorDayKey` und `lastSetCompletedAt` im Coordinator + Tests geprueft.
6. Regression abgesichert durch gruenen Analyze-/Testlauf (`workout_session_coordinator_test`, `workout_day_screen_test`).

---

## 1. Zielverhalten (Single Source of Truth)

### 1.1 Startregeln

- [x] Start ueber grossen Play-Button auf Profilseite startet Training + Timer sofort.
- [x] Start ueber Gym-Page oder NFC fuegt Session zur WorkoutDay hinzu.
- [x] Bei Gym/NFC startet der Timer erst, wenn auf WorkoutDay der erste Satz abgehakt wird.
- [x] Es gibt keinen zweiten parallelen Startpfad mit abweichender Logik.

### 1.2 Endregeln (manuell)

- [x] Klick auf `Training speichern` auf WorkoutDay beendet Training deterministisch.
- [x] Klick auf grossen Stop-Button auf Profilseite beendet Training deterministisch.
- [x] Beide manuellen Endpunkte nutzen denselben Finish-Orchestrator.
- [x] Nach manuellem Ende: Navigation zur Profilseite, dann Session-Highlights stabil anzeigen.

### 1.3 Endregeln (automatisch bei Vergessen)

- [x] Wenn 60 Minuten kein Satz mehr abgehakt wurde, wird Training automatisch beendet.
- [x] Endzeit = Timestamp des zuletzt abgehakten Satzes.
- [x] Dauer = Startzeit bis letzter abgehakter Satz.
- [x] Auto-Ende triggert denselben Save-/Finalize-Flow wie manuelles Ende.
- [x] Falls App nicht offen ist: Highlights werden als ausstehend gespeichert und beim naechsten App-Start angezeigt.

### 1.4 Tageslogik (harte Invariante)

- [x] Alle Daten einer Trainingseinheit gehoeren immer zum Starttag (Session-Anchor-Day).
- [x] Start vor Mitternacht und Ende nach Mitternacht bleibt genau ein Trainingstag.
- [x] Das gilt identisch fuer manuelles Ende und Auto-Ende.

---

## 2. Architekturprinzipien (fuer Wartbarkeit)

- [x] Ein zentraler `WorkoutSessionCoordinator` ist die einzige Instanz fuer Start/Stop/AutoStop.
- [ ] Klarer Zustandsautomat statt verstreuter Flags.
- [ ] Ein Event-Contract fuer `SessionCompleted` (manuell + auto).
- [~] Idempotente Persistenz: derselbe Abschluss darf nie doppelt gespeichert werden.
- [x] Keine konkurrierenden NFC-Startpfade ohne gemeinsame Orchestrierung.

Empfohlener Zustandsautomat:

- [ ] `Idle`
- [ ] `Running` (mit `startAt`, `anchorDayKey`, `lastSetCompletedAt?`)
- [ ] `Finalizing` (save/discard in progress)
- [ ] `CompletedPendingHighlights` (Summary vorhanden, UI-Ausspielung noch offen)
- [ ] `CompletedShown`

---

## 3. Umsetzungsphasen

## Phase 0: Spezifikation einfrieren

Ziel: Keine Rest-Mehrdeutigkeit vor Coding.

- [x] Product-Decision-Record fuer alle Start-/Stop-Regeln schreiben (`docs/ToDos/workoutflow_phase0_pdr.md`).
- [x] Exakte Begriffe fixieren:
  - `Training gestartet`
  - `Satz abgehakt`
  - `Training beendet`
  - `Trainingstag`
- [x] Edge-Cases dokumentieren:
  - Profil-Start ohne einen einzigen Satz
  - App kill/background waehrend Running
  - Netz offline beim Finalize
- [x] Akzeptanzkriterien pro Regel schriftlich fixieren.

Exit-Kriterium:

- [~] Team hat eine abgestimmte, testbare Soll-Spezifikation (PDR erstellt, Review/Freigabe offen).

## Phase 1: Zentralen Coordinator einfuehren

Ziel: Alle bisherigen Start/Stop-Wege auf einen Orchestrator legen.
Hinweis: Dieser Abschnitt ist die technische Phase 1 und ist bereits final abgeschlossen; die Checkboxen in Abschnitt 1.1-1.4 sind uebergeordnete End-to-End-Zielkriterien ueber mehrere Phasen.

- [x] `WorkoutSessionCoordinator` implementieren (Start/Stop/AutoStop).
- [x] Timer-Service nur noch als technische Zeitquelle, nicht als Business-Orchestrator.
- [x] `anchorDayKey` bei Session-Start persistieren.
- [x] `lastSetCompletedAt` bei jedem Satz-Abhaken persistieren.
- [x] API des Coordinators:
  - [x] `startFromProfilePlay(...)`
  - [x] `onExerciseAddedFromGymOrNfc(...)`
  - [x] `onFirstSetCompleted(...)` (via Set-Completion Pfad)
  - [x] `finishManuallyFromWorkoutSave(...)`
  - [x] `finishManuallyFromProfileStop(...)`
  - [x] `finishAutomaticallyAfterInactivity(...)`

Exit-Kriterium:

- [x] Alle UI-Einstiegspunkte rufen nur noch den Coordinator auf.

## Phase 2: Startflows konsolidieren

Ziel: Deterministisches Startverhalten gemaess Zielbild.

- [x] Profil-Play startet immer sofort Timer + Session-Kontext.
- [x] Gym/NFC fuegt Session nur hinzu; Timer startet erst bei erstem abgehakten Satz.
- [x] Doppelte NFC-Logik zusammenfuehren (globaler Listener + Button ueber gemeinsame Service-Schicht).
- [x] Debounce/Guard gegen doppelte Session-Erzeugung bei Mehrfach-Events.

Exit-Kriterium:

- [x] Kein Startpfad kann den Timer unerwartet doppelt starten oder offen lassen.

## Phase 3: Endflows konsolidieren (manuell)

Ziel: `Training speichern` und Profil-Stop verhalten sich funktional gleich.

- [x] Gemeinsamen `finishAndFinalize(...)` Pfad nutzen.
- [x] Einheitliche Validierung offener Saetze (bestaetigen/auto-complete je nach Produktregel).
- [x] Einheitliche Persistenz-Reihenfolge (lokal first, remote sync, meta, highlights-queue).
- [x] Einheitliche Navigation nach Erfolg (Profilseite).

Exit-Kriterium:

- [x] Beide manuellen Endwege liefern identische fachliche Resultate.

## Phase 4: Auto-Ende nach 60 Minuten Inaktivitaet

Ziel: Vergessenes manuelles Ende robust abfangen.

- [x] Inaktivitaets-Timer an `lastSetCompletedAt` koppeln (nicht an UI-Ticks).
- [x] Nach exakt 60 Minuten ohne neuen abgehakten Satz finalisieren.
- [x] Endzeit explizit auf `lastSetCompletedAt` setzen.
- [x] Falls keine abgeschlossenen Saetze vorhanden:
  - [x] Klar definierter Fallback (empfohlen: discard ohne Highlights).
- [x] Auto-Ende muss bei App-Restart rekonstruiert werden (persistenter State).

Exit-Kriterium:

- [x] Auto-Ende funktioniert auch nach App-Kill/Neustart korrekt.

## Phase 5: Highlights robust und nachholbar machen

Ziel: Highlights gehen nie verloren.

- [x] Persistente `pending_highlights` Queue einfuehren (lokal).
- [x] Bei jedem erfolgreichen Finalize: Highlight-Payload enqueue.
- [x] Beim App-Start: Queue verarbeiten und Dialog anzeigen.
- [x] Nach erfolgreicher Anzeige: Item als `shown` markieren/entfernen.
- [x] Idempotenz-Guard: Gleiches Highlight nicht doppelt zeigen.

Exit-Kriterium:

- [x] Auto-beendete Sessions zeigen Highlights spaeter sicher nach (auch Tage spaeter).

## Phase 6: Starttag-Invariante hart durchziehen

Ziel: Alle Daten konsequent dem Starttag zuordnen.

- [x] `anchorDayKey` und `anchorStartAt` als Pflichtfelder in Session-Meta.
- [x] Alle Writes (Session, XP, Story, Meta, Stats) nutzen `anchorDayKey`.
- [x] Keine Berechnung mit `DateTime.now()` fuer DayKey beim Finalize.
- [x] Regression-Check fuer Mitternachts-Szenarien im gesamten Save-Flow.

Exit-Kriterium:

- [x] Mitternachts-Workouts landen immer im Starttag, unabhaengig vom Endzeitpunkt.

## Phase 7: Datenkonsistenz und Sync-Haertung

Ziel: Fehler robust abfangen, keine Duplikate/Inkonsistenzen.

- [x] Abschlussoperation idempotent machen (`finalizeToken` / `finalizedAt` Guard).
- [x] Duplicate-save Guard fuer denselben Session-Abschluss.
- [x] Offline-first sauber: lokal commit -> sync queue -> retry/backoff.
- [x] Delete-/Create-Syncpfade entkoppeln und klar strukturieren.
- [x] Einheitliche Fehlercodes + User-Messages fuer alle Endpfade.

Exit-Kriterium:

- [x] Wiederholte Trigger erzeugen keine doppelte Session oder doppelte XP.

## Phase 8: Teststrategie (idiotensicher)

Ziel: Alle kritischen Wege automatisiert abgesichert.

### 8.1 Pflicht-Testmatrix (E2E + Integration)

- [x] Profil-Play -> Sätze -> `Training speichern` -> Profil -> Highlights.
- [x] Profil-Play -> Sätze -> Profil-Stop -> Profil -> Highlights.
- [x] Gym-Start -> erster Satz -> Timer startet -> Save -> Highlights.
- [x] NFC-Start -> erster Satz -> Timer startet -> Save -> Highlights.
- [x] Start 23:00, Ende 00:30 -> alles auf Starttag.
- [x] Start 23:00, Auto-Ende 01:00 (letzter Satz 23:40) -> Endzeit 23:40, Starttag.
- [x] App kill waehrend Running -> Neustart -> Auto-Ende/Finalize korrekt.
- [x] Auto-Ende bei geschlossener App -> Highlights beim naechsten App-Open.
- [x] Offline beim Finalize -> spaeterer Sync ohne Doppelbuchung.

### 8.2 Nicht-funktionale Tests

- [x] Performance: kein UI-Jank beim Finalize/Highlights.
- [x] Soak-Test: 50+ Sessions ohne Speicherleck/Timer-Drift.
- [x] Recovery-Test: Corrupt/partial local state wird defensiv behandelt.

### 8.3 Post-Phase Hotfix-Regressionen

- [x] Profil-Play startet Timer und navigiert deterministisch auf Gym-Tab (kein Verbleib auf Profil).
- [~] `Training speichern` beendet Session und setzt grossen Profil-Button deterministisch auf Play zurueck (Hotfix 5/6/7/8 implementiert, manuelle Device-Verifikation offen).
- [x] Finish-Flow zeigt Result-Snackbar context-sicher nach Navigation (kein deactivated-context Crash).
- [x] Coordinator-Dispose-Races fuehren nicht mehr zu `used after disposed` im Start-/Finalize-Flow.

Exit-Kriterium:

- [~] Alle Muss-Szenarien gruen in CI + manueller Smoke-Test.

## Phase 9: Observability, Rollout, Launch-Gate

Ziel: Sicherer Launch mit kontrolliertem Risiko.

- [ ] Telemetrie-Events vereinheitlichen:
  - [ ] `workout_started`
  - [ ] `first_set_completed`
  - [ ] `workout_finalized_manual`
  - [ ] `workout_finalized_auto`
  - [ ] `highlights_enqueued`
  - [ ] `highlights_shown`
- [ ] Dashboards/Alerts fuer:
  - [ ] finalize-fail-rate
  - [ ] duplicate-finalize-rate
  - [ ] pending-highlights-age
- [ ] Feature-Flags fuer schrittweisen Rollout.
- [ ] Rollback-Plan dokumentieren.

Launch-Gate (alle Punkte Pflicht):

- [ ] Start-/Stop-Regeln exakt gem. Zielverhalten.
- [ ] Auto-Ende 60 min stabil inkl. last-set-Endzeit.
- [ ] Starttag-Invariante in allen Datenstroemen.
- [ ] Highlights-Nachholung bei spaeterem App-Start stabil.
- [ ] Keine bekannten P1/P2-Bugs offen.

---

## 4. Arbeits-Checkliste fuer die direkte Abarbeitung

### 4.1 Sofort (Sprint 1)

- [~] Phase 0 komplett abschliessen.
- [x] Coordinator-Grundgeruest + State Machine (Phase 1).
- [x] Startflow-Konsolidierung Profil/Gym/NFC (Phase 2).

### 4.2 Danach (Sprint 2)

- [x] Endflow-Konsolidierung manuell (Phase 3).
- [x] Auto-Ende inklusive Restart-Recovery (Phase 4).

### 4.3 Danach (Sprint 3)

- [x] Highlights-Queue mit sicherem Replay (Phase 5).
- [x] Starttag-Invariante in allen Writes durchziehen (Phase 6).

### 4.4 Danach (Sprint 4)

- [x] Sync-Haertung und Idempotenz finalisieren (Phase 7).
- [~] Vollstaendige Testmatrix + CI-Gates (Phase 8).
- [ ] Rollout + Launch-Gate (Phase 9).

---

## 5. Definition of Done (final)

- [ ] Der Timer startet nur in den gewuenschten Situationen.
- [ ] Der Timer endet nur ueber die definierten manuellen Endpunkte oder Auto-Ende nach 60 Minuten ohne Satzabhaekung.
- [ ] Endzeit beim Auto-Ende ist immer der letzte Satz-Timestamp.
- [ ] Session, XP, Meta, Story und Highlights sind immer dem Starttag zugeordnet.
- [ ] Highlights erscheinen sofort nach manuellem Ende und spaeter bei naechstem App-Start nach Auto-Ende.
- [ ] Der Flow ist idempotent, testbar, beobachtbar und rollout-sicher.
