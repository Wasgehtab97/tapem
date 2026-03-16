# Roadmap 2026-03-12 - Backlog Punkt 4
## Thema
Satzanzahl pro Trainingsplan übernehmen (statt immer Default = 3).

## Zielbild
- Bei Plan-Workouts wird die initiale Satzanzahl aus der letzten Plan-Session übernommen.
- Ohne Historie bleibt Default `3`.
- Einstellung ist planbezogen, nicht geräte- oder übungsbezogen.

## Ist-Analyse (Code)
- Aktuelle Initialisierung immer mit 3 Sets: `lib/core/providers/device_provider.dart` (`_defaultInitialSetCount`, `_buildInitialEmptySets`).
- Plan-Kontext wird im Workout gehalten: `lib/features/device/presentation/controllers/workout_day_controller.dart` (`setPlanContext/getPlanContext`).
- Plan-Abschluss-Meta wird bereits gespeichert: `lib/features/device/presentation/workout_finish_flow.dart` (Session-Meta mit `planId`).
- Plan-Datenmodell hat noch kein Feld für Set-Default: `training_plan.dart`.

## Umsetzungsstrategie
- Planmodell um ein planweites Feld erweitern (z. B. `defaultSetCount`).
- Beim Workout-Start im Plan-Kontext diesen Wert als Initial-Setcount in neue Sessions injizieren.
- Beim erfolgreichen Speichern eines Plan-Workouts den neuen Wert aus der Session aktualisieren.

## Ziel-Datenmodell (Vorschlag)
- In `TrainingPlan` neues Feld:
- `defaultSetCount` (`int`, optional, validiert >= 1, fallback 3).
- Bei Save/Read vollständig serialisieren.

## Meilensteine
### M1 - Domain + Persistence erweitern
- [x] `TrainingPlan` um `defaultSetCount` ergänzt (`copyWith/fromJson/toJson/props`).
- [x] `DraftTrainingPlan` um `defaultSetCount` erweitert, damit Edit-Saves den Wert nicht verlieren.
- [x] Firestore-Write/Read kompatibel gehalten (fehlendes/invalides Feld -> fallback `3`).

### M2 - Initialisierungspfad für Session-Provider öffnen
- [x] `DeviceProvider.loadDevice(...)` um optionalen Parameter `initialSetCountOverride` erweitert.
- [x] `_buildInitialEmptySets` auf konfigurierbaren Initial-Count umgestellt.
- [x] Untergrenze hart abgesichert (`>= 1`, fallback `3`) und als Provider-State (`_initialSetCount`) stabilisiert.

### M3 - Planbezogenen Count in den Workout-Start einspeisen
- [x] `WorkoutDayController` führt pro Session optionalen `initialSetCountOverride`.
- [x] `addOrFocusSession` übernimmt den Initial-Count explizit oder aus aktivem Plan-Kontext.
- [x] `WorkoutDayScreen/_ensureSession` setzt/übernimmt Plan-Kontext inkl. Initial-Count vor `loadDevice`.
- [x] Session-Loader (`device_session_section`, `workout_day_table_card`) geben den Session-Override deterministisch an `loadDevice` weiter.

### M4 - Rückschreiben nach erfolgreichem Plan-Workout
- [x] Nach `endDay`/`saveAndFinish` wird bei vorhandener `planId` der planweite Satzwert berechnet.
- [x] Regel umgesetzt: `Mode` über `done + filledNotDone` je Session; bei Gleichstand gewinnt der höhere Set-Count.
- [x] Persistenz umgesetzt über `training_plans/{planId}.defaultSetCount` (`updateDefaultSetCount`).
- [x] Fehlerpfad non-blocking gehalten (separate `try/catch` für Stats, Default-Set-Update, Session-Meta).

### M5 - Tests und Regression
- [x] Unit-Tests für Fallback/Clamp ergänzt (`training_plan_serialization_test`).
- [x] Controller-Test ergänzt: Plan-Kontext `defaultSetCount=5` führt zu initial `5` Sets (`workout_day_local_catalog_integration_test`).
- [x] Flow-Tests ergänzt: Mode-/Tie-Break-Resolver im `WorkoutFinishFlow` (`workout_finish_flow_test`).
- [x] Rückschreiblogik ist über dedizierten Writer-Hook testbar (`debugSetPlanDefaultSetCountWriter`).

## Backend/Datenseite
- Keine neue Collection zwingend notwendig.
- Firestore Rules für `training_plans` erlauben owner/coaching writes bereits.
- Optional: Firestore-Regel für Datentyp validieren (wenn stricter Governance gewünscht).

## Qualitäts-Gates vor Launch
- [x] `flutter analyze`
- [x] Relevante Widget/Unit-Tests grün
- [x] Technischer End-to-End-Pfad automatisiert verifiziert:
- [x] Plan-Initialisierung auf `5` Sets + Persistenzpfad für `defaultSetCount` im Finish-Flow.

## Status
- [x] Roadmap vollständig umgesetzt (code + tests + analyze) und launch-ready vorbereitet.

## Risiken
- Unklare Berechnung bei unterschiedlichen Setcounts pro Session.
- Gegenmaßnahme: Produktregel fixieren (Mode/Median/letzte Session) und im Code kommentieren.
