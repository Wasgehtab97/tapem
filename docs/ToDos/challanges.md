# Challenges: Ist-Zustand, Erweiterung, Roadmap

Stand: 2026-02-18  
Scope: App-Client (Flutter) mit Spark-Plan (ohne produktive Cloud Functions)

## Kurzfazit

Das aktuelle Challenge-System war primär auf geraetegebundene Satz-Ziele ausgelegt.  
Jetzt ist zusaetzlich eine zweite Challenge-Variante eingebaut:

- `Geraete-Saetze` (bestehend)
- `Trainingshaeufigkeit` (neu): z. B. `2x/3x/4x in 1 Kalenderwoche` oder `4x/8x/12x/16x in 4 Kalenderwochen`

Wichtig fuer dein Setup: Die Completion-Logik bleibt rein clientseitig (Spark-kompatibel), keine neue Abhaengigkeit von Cloud Functions.

## Ist-Zustand (vor der Erweiterung)

## Frontend

- Admin-Erstellung von Challenges in `lib/features/admin/presentation/screens/challenge_admin_screen.dart`
- Aktive/abgeschlossene Challenges in:
  - `lib/features/challenges/presentation/widgets/active_challenges_widget.dart`
  - `lib/features/challenges/presentation/widgets/completed_challenges_widget.dart`
- Challenge-Tab in:
  - `lib/features/challenges/presentation/screens/challenge_tab.dart`

Funktional vorher:
- Challenge-Definition basierte auf:
  - Titel/Beschreibung
  - XP-Reward
  - Zeitraum (woechentlich oder monatlich)
  - Geraeteauswahl
  - `minSets` als Ziel

## Backend-/Datenlogik (im Client)

- Datenmodell in `lib/features/challenges/domain/models/challenge.dart`
- Firestore-Quelle + Auswertung in `lib/features/challenges/data/sources/firestore_challenge_source.dart`
- Admin-Create-Service in `lib/features/admin/data/services/challenge_admin_service.dart`

Completion vorher:
- Beim Session-Save wird `checkChallenges(...)` getriggert.
- Fortschritt wurde als Log-Anzahl (Saetze) im Zeitraum geprueft.
- Bei Zielerreichung:
  - Eintrag in `gyms/{gymId}/users/{userId}/completedChallenges/{challengeId}`
  - Badge in `users/{userId}/badges/{challengeId}`
  - XP-Update in `gyms/{gymId}/users/{userId}/rank/stats`

## Cloud Functions

- Es existiert parallel alte Trigger-Logik in `functions/index.js`.
- Fuer deinen Spark-Betrieb ist sie aktuell nicht der produktive Pfad.
- App-seitig bleibt die Challenge-Auswertung weiterhin voll funktionsfaehig ohne Functions.

## Umsetzung dieser Erweiterung

## Neu im Datenmodell

In `lib/features/challenges/domain/models/challenge.dart`:

- Neues Zieltyp-Konzept:
  - `device_sets`
  - `workout_days`
- Neue Felder:
  - `targetWorkouts`
  - `durationWeeks`

Damit sind beide Challenge-Arten in einem Modell abbildbar.

## Neu im Admin-Flow

In `lib/features/admin/data/services/challenge_admin_service.dart` und  
`lib/features/admin/presentation/screens/challenge_admin_screen.dart`:

- Neue Goal-Auswahl:
  - `Geraete-Saetze`
  - `Trainingshaeufigkeit`
- Trainingshaeufigkeit:
  - Zielanzahl Trainings (`targetWorkouts`)
  - Zeitfenster (`1` oder `4` Kalenderwochen)
  - Start-KW
- Validierung:
  - Workout-Frequenz aktuell nur auf Wochenbasis (nicht Monatsmodus)
  - Satz-Challenge weiterhin mit Geraeteauswahl + `minSets`

## Neu in der Auswertung (Spark-kompatibel)

In `lib/features/challenges/data/sources/firestore_challenge_source.dart`:

- Satz-Challenge:
  - unveraendert: Log-/Satzzaehlung im Zeitraum (optional geraetegefiltert)
- Trainingshaeufigkeit:
  - zaehlt eindeutige Trainingstage im Zeitraum
  - damit zaehlt ein langer Workout-Tag nicht unnoetig mehrfach

## UI-Anzeige verbessert

In `lib/features/challenges/presentation/widgets/active_challenges_widget.dart`:

- Zieltext im Active-Card/Detaildialog jetzt typabhaengig:
  - `Ziel: X Saetze`
  - `Ziel: X Trainings in Y Kalenderwochen`

## Tests

Aktualisiert in `test/features/admin/data/services/challenge_admin_service_test.dart`:

- Bestehende Weekly/Monthly Satz-Challenges
- Neuer Workout-Frequenz-Case (4 Wochen)
- Validierungsfall: Workout-Frequenz + Monatsmodus wird abgelehnt

## Lokalisierung

Neue Challenge-Strings in:

- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`

Generierung aktualisiert via `gen-l10n`.

## Roadmap (Checklist) bis zum "coolen" Challenge-System

## Phase 1: Stabilisieren (direkt)

- [x] Zweite Challenge-Art "Trainingshaeufigkeit" einfuehren
- [x] Admin-UI fuer 1 oder 4 Kalenderwochen erweitern
- [x] Spark-kompatible clientseitige Auswertung sicherstellen
- [x] Zielanzeige in Active Challenges verbessern
- [ ] Progress-Balken live pro Challenge anzeigen (x/y)
- [ ] Completion-Animation + Reward-Moment staerker inszenieren

## Phase 2: Motivation und Variety

- [ ] Challenge-Templates (quick create) fuer Owner anlegen
- [ ] Schwierigkeitstufen (`leicht`, `mittel`, `hart`) mit XP-Spannen
- [ ] Rotierende Wochen-Highlights (automatisch vorgeschlagen)
- [ ] Team-/Community-Challenges (optional spaeter bei Blaze)

## Phase 3: Langfristige Bindung

- [ ] Streak-Challenges ueber mehrere Wochen
- [ ] Saisonale Challenge-Serien (z. B. 6-Wochen-Cycle)
- [ ] Personalisierte Vorschlaege je Aktivitaetsniveau
- [ ] Analytics: Completion-Rate je Challenge-Typ messen

## Konkrete "coole" Challenge-Ideen

## Einfach erreichbar (dranbleiben)

- `Wochenstart`: Trainiere 2x in 1 Kalenderwoche
- `Routine-Builder`: Trainiere 3x in 1 Kalenderwoche
- `Konstanz`: Trainiere 8x in 4 Kalenderwochen

## Ehrgeizig (mit Prestige)

- `Unstoppable`: Trainiere 4x in 1 Kalenderwoche
- `12er Fokusblock`: Trainiere 12x in 4 Kalenderwochen
- `16er Monsterblock`: Trainiere 16x in 4 Kalenderwochen

## Fun + Ehrgeiz kombiniert

- `No-Zero-Week`: In 4 Wochen keine Woche ohne Training
- `Weekend-Warrior`: An 4 Wochenenden in Folge trainieren
- `Comeback-Challenge`: Nach 7+ Tagen Pause wieder 3x in 7 Tagen trainieren

## Optional naechste Challenge-Arten (spaeter)

- `Diversity-Challenge`: trainiere an X verschiedenen Geraeten
- `Consistency-Challenge`: trainiere an X verschiedenen Tagen pro Woche
- `Volume-Challenge`: erreiche X Gesamt-Wiederholungen im Zeitraum
- `Social-Challenge`: absolviere X Workouts mit Freundes-Feature/Community-Bezug

## Technische Hinweise fuer den Spark-Betrieb

- Challenge-Completion bleibt aktuell absichtlich im App-Client.
- Dadurch ist der Kernflow auch ohne Cloud Functions nutzbar.
- Bei spaeterem Blaze-Upgrade kann ein serverseitiger Reconcile-Job ergaenzt werden (Fraud-Hardening, zentrale Auswertung), ohne die neue Datenstruktur erneut zu aendern.
