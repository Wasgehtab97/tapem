# Roadmap 2026-03-12 - Backlog Punkt 2
## Thema
Zeitplanung für Trainingspläne (Wochentage/Rhythmus) und automatische Default-Planauflösung beim Start.

## Status
- Letzte Aktualisierung: 2026-03-12
- Fortschritt: M1-M5 vollständig umgesetzt
- Launch-Readiness: vollständig launch-ready

## Zielbild
- Jeder Trainingsplan kann optional eine Schedule-Definition haben.
- Für das aktuelle Datum wird beim Start automatisch der passende Plan ermittelt.
- Manuelle Tageszuweisungen bleiben möglich und haben Priorität.

## Ist-Analyse (Code)
- Trainingsplan-Modell: `lib/features/training_plan/domain/models/training_plan.dart`.
- Tageszuweisungen: `lib/features/training_plan/domain/models/training_day_assignment.dart` + `training_schedule` Collection.
- Startlogik: `lib/features/profile/presentation/screens/profile_screen.dart` (`_handleStartTraining`).
- Plan-Übersicht: `lib/features/training_plan/presentation/screens/plan_overview_screen.dart`.

## Umsetzungsstrategie
- Schedule als Teil des Plan-Domänenmodells führen (nicht in `training_schedule`, da dort aktuell nur `dateKey/planId` erlaubt ist).
- Auflösung in klarer Priorität:
- 1) explizite Tageszuweisung (`training_schedule`)
- 2) Schedule-Match aus Plan-Definition
- 3) Fallback (bestehendes Verhalten).

## Ziel-Datenmodell (Vorschlag)
- Neues Value Object `TrainingPlanSchedule` (neu):
- Felder: `enabled`, `mode` (`weekly` | `everyXDays`), `weekdays[]`, `intervalDays`, `anchorDate`.
- Im Plan speichern als `schedule` (optional).
- Keine Breaking Changes: alte Pläne ohne `schedule` funktionieren unverändert.

## Meilensteine
### M1 - Domain + Serialization
- [x] `training_plan_schedule.dart` angelegt.
- [x] `TrainingPlan` um optionales Feld `schedule` erweitert.
- [x] `fromJson/toJson/copyWith/props` erweitert.
- [x] Backward Compatibility für Pläne ohne `schedule` sichergestellt.

### M2 - Plan-Builder + UI
- [x] `DraftTrainingPlan` um `schedule` erweitert.
- [x] `plan_builder_provider.dart` um Schedule-Update-Methoden erweitert.
- [x] Scheduling-UI in `plan_detail_screen.dart` ergänzt.
- [x] Weekly-Mode (Wochentage-Auswahl) umgesetzt.
- [x] Every-X-Days-Mode (Intervall + Startdatum) umgesetzt.

### M3 - Resolver für "heute passender Plan"
- [x] Resolver in `training_plan_schedule_resolver.dart` gekapselt.
- [x] `ProfileScreen._handleStartTraining` um Resolver-Aufruf ergänzt.
- [x] Prioritätsregeln umgesetzt: manuelle Tageszuweisung vor auto Schedule.

### M4 - Default-Startverhalten stabilisieren
- [x] Resolver-Kandidat wird als Default in Startflow übernommen.
- [x] Bei mehreren Kandidaten wird ein Auswahl-Dialog erzwungen (keine stille Auto-Wahl).
- [x] Bei keinem Kandidaten bleibt bestehender Freestyle-/Plan-Picker-Pfad.

### M5 - Tests + Datenintegrität
- [x] Unit-Tests für Resolver (Wochentage, Intervall, Recency, disabled) ergänzt.
- [x] Zusätzliche Edge Cases über Monats-/Jahreswechsel ergänzt.
- [x] Flow-Entscheidungstests für `_handleStartTraining`-Pfadlogik ergänzt (plan resolution + start decision).
- [x] Serialization-Tests für `TrainingPlan` mit/ohne `schedule` ergänzt.

## Backend/Datenseite
- Firestore Rules für `training_plans` erlauben bereits flexible Felder -> i. d. R. keine Rules-Änderung nötig.
- Keine neue Collection zwingend erforderlich.
- Optional später: Composite-Index nur falls neue Queries mit `schedule.*` eingeführt werden.

## Qualitäts-Gates vor Launch
- [x] `flutter analyze` (betroffene Dateien) grün.
- [x] Neue Resolver-Unit-Tests grün.
- [x] Zusätzliche Flow-/Serialization-Tests grün.
- [x] Datumspfad über mehrere Kalendertage (inkl. Monats-/Jahreswechsel) testseitig abgesichert.
- [x] Fallback-Verhalten ohne harte Abhängigkeit auf Assignment/Schedule robust implementiert.

## Risiken
- Mehrdeutige Regeln bei mehreren passenden Plänen.
- Gegenmaßnahme: deterministische Sortierung (z. B. `updatedAt desc`) und klarer Produktentscheid bei Kollision.
