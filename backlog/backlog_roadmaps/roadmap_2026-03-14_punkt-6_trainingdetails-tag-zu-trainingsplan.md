# Roadmap 2026-03-14 - Backlog Punkt 6
## Thema
Trainingsplan direkt aus der Training-Details-Seite eines Tages erstellen ("Freestyle-Tag -> als Plan speichern").

## Status
- Letzte Aktualisierung: 2026-03-14
- Fortschritt: M0-M3 umgesetzt, M4-M8 offen/teilweise
- Launch-Readiness: nicht gestartet

## Zielbild
- Auf der Training-Details-Seite kann der User mit einer Aktion aus allen Übungen des ausgewählten Tages einen neuen Trainingsplan erstellen.
- Der User gibt nur den Plan-Namen ein.
- Der neue Plan erscheint direkt in den eigenen Trainingsplänen.
- Reihenfolge der Übungen bleibt erhalten (wie am Trainingstag ausgeführt), Duplikate werden deterministisch behandelt.
- Lösung ist robust bei Offline/Cache/Legacy-Daten und wartbar über klar getrennte Verantwortlichkeiten (UI, Mapping, Persistenz, Tests).

## Scope
- In Scope:
- Training-Details-UI-Aktion + Naming-Dialog + Save-Flow.
- Extraktion der Plan-Übungen aus Tages-Sessions.
- Persistenz als normaler `training_plans`-Datensatz.
- Provider-Invalidierung + Navigation/Feedback nach Erstellung.
- Tests (Unit + Widget + optional Integrationsnah).
- Out of Scope:
- Automatische Plan-Zuweisung für den Tag nach Erstellung.
- Plan-Generator mit Satz/Reps-Templates je Übung.
- Änderungen am Trainingsplan-Schedule-Feature.

## Ist-Analyse (Frontend + Backend)
- Training-Details lädt Sessions über `trainingDetailsStateProvider` und rendert sie in Reihenfolge:
- `lib/features/training_details/presentation/screens/training_details_screen.dart`
- `lib/core/providers/training_details_provider.dart`
- Session-Datenmodell:
- `lib/features/training_details/domain/models/session.dart`
- Bestehender Trainingsplan-Stack:
- Domain: `lib/features/training_plan/domain/models/training_plan.dart`, `training_plan_exercise.dart`
- Save-Logik: `lib/features/training_plan/application/plan_builder_provider.dart`
- Repository/Source: `lib/features/training_plan/data/repositories/training_plan_repository_impl.dart`, `lib/features/training_plan/data/sources/firestore_training_plan_source.dart`
- Plan-Liste/Detail:
- `lib/features/training_plan/presentation/screens/plan_overview_screen.dart`
- `lib/features/training_plan/presentation/screens/plan_detail_screen.dart`
- Firestore-Pfade:
- `users/{uid}/training_plans/{planId}`
- `users/{uid}/training_plans/{planId}/meta/stats`
- `users/{uid}/training_schedule/{dateKey}`
- Tages-Meta (u. a. `planId`, `planName`) liegt separat unter:
- `gyms/{gymId}/users/{uid}/session_meta/{dayKey}` (via `SessionMetaSource`)
- Relevante Rules bereits vorhanden für `training_plans`/`training_schedule`:
- `firestore.rules` (Match-Blöcke ab Zeile ~711, ~725, ~754)

## Technische Leitentscheidungen
- Empfehlung: Feature als eigenen Application-Usecase bauen (nicht direkt ad-hoc nur im Widget), z. B.:
- `CreateTrainingPlanFromDayUseCase`
- Ziel: Mapping/Validierung/Persistenz testbar und wiederverwendbar halten.
- Übungs-Mapping:
- Key: `deviceId + exerciseId`
- Reihenfolge: erste Vorkommnisse in Tagesreihenfolge
- Name: bevorzugt `exerciseName`, fallback `deviceName`
- Filter: ungültige Datensätze ohne IDs ausschließen (Legacy-Schutz)
- Ownership:
- Standardmäßig nur für aktuell eingeloggten User speichern.
- Wenn Training-Details für fremde User geöffnet ist (z. B. Coaching/Friends), Aktion initial ausblenden oder explizit als separaten Scope definieren.

## Meilensteine
### M0 - Produkt- und Datenregeln festziehen
- [x] Sichtbarkeit der Aktion eindeutig festlegen (nur eigener User vs. auch Coach-Client-Ansicht).
- [x] Duplikatregel finalisieren (`deviceId+exerciseId` dedupe, erste Instanz gewinnt).
- [x] Verhalten bei `0` validen Übungen definieren (Fehlermeldung, kein Save).
- [x] Naming-Regeln definieren (trim, min/max Länge, leere Namen blocken).

### M1 - Application-Layer für "Plan aus Tag"
- [x] Neuen Usecase/Service anlegen (`training_plan/application`).
- [x] Reine Mapping-Funktion implementieren (`List<Session> -> List<TrainingPlanExercise>`).
- [x] Validierung kapseln (gymId/userId vorhanden, mindestens 1 Übung).
- [x] Persistenz über `TrainingPlanRepository.savePlan(...)` anbinden.
- [x] Rückgabemodell definieren (z. B. `planId`, `exerciseCount`, evtl. Warnungen zu gefilterten Sessions).

### M2 - UI-Einstieg auf Training-Details-Seite
- [x] Primäre Aktion in `TrainingDetailsScreen` ergänzen (z. B. AppBar-Action oder CTA-Card).
- [x] Dialog/Sheet für Plan-Namen hinzufügen (nur Name, kein unnötiger Zusatzflow).
- [x] Loading/Disable-State während Erstellung integrieren.
- [x] Erfolgs-/Fehler-Snackbar lokalisieren.

### M3 - Persistenz + Provider-Refresh + Navigation
- [x] Nach Save `trainingPlansProvider` invalidieren.
- [x] Optional: direkt in Plan-Detail navigieren (`AppRouter.trainingPlanDetail`) oder auf Plan-Übersicht bleiben (Produktentscheidung M0).
- [x] Sicherstellen, dass neuer Plan sofort in `PlanOverviewScreen` sichtbar ist.
- [x] Save idempotent pro Klick schützen (Double-Submit verhindern).

### M4 - Kompatibilität mit bestehender Trainingsplan-Architektur
- [ ] Plan-Felder konsistent setzen (`id`, `name`, `gymId`, `exercises`, `colorIndex`, `schedule`, `defaultSetCount`).
- [ ] Kein unbeabsichtigtes Überschreiben bestehender Pläne.
- [ ] Keine Seiteneffekte auf `training_schedule` (außer explizit gewünscht).
- [ ] Sicherstellen, dass Plan im bestehenden Editor/Start-Flow normal funktioniert.

### M5 - Edge Cases und Robustheit
- [ ] Legacy-Sessions ohne `exerciseId` sicher behandeln.
- [ ] Multi- vs. Single-Device-Sessions korrekt mappen.
- [ ] Sessions mit fehlenden Namen robust fallbacken.
- [ ] Fehlerpfade für Offline/Timeout abdecken (freundliche Fehlermeldung, kein Crash).

### M6 - Tests
- [x] Unit-Tests für Mapping/Validierung (Dedup, Reihenfolge, Fallback-Name, leere Inputs).
- [ ] Widget-Test für Training-Details-Aktion (Dialog öffnet, Name validiert, Save ausgelöst).
- [x] Provider-/Usecase-Test mit Fake-Repository (Save-Aufruf + Payload korrekt).
- [ ] Regressionstest: neu erstellter Plan erscheint in Plans-Liste.

### M7 - Lokalisierung, Logging, Observability
- [x] Neue Texte in `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` ergänzen.
- [x] `flutter gen-l10n` ausführen.
- [x] Strukturierte Logs hinzufügen (z. B. `plan_from_day_started/succeeded/failed`).
- [ ] Logging ohne sensible Inhalte (nur IDs/Counts, keine unnötigen Nutzerdaten).

### M8 - QA-Gates und Rollout
- [x] `flutter analyze` auf betroffene Dateien ohne neue Warnungen.
- [x] Relevante Tests grün.
- [ ] Manuelle QA-Matrix durchspielen:
- [ ] Tag mit vielen Übungen
- [ ] Tag mit Duplikaten derselben Übung
- [ ] Tag mit unvollständigen Legacy-Sessions
- [ ] Offline/Online-Wechsel
- [ ] Coaching/Friend-Ansicht (Aktion korrekt sichtbar/unsichtbar)

## Implementierungsreihenfolge (empfohlen)
1. M0 (Regeln fixieren)
2. M1 (Usecase + Mapping + Tests zuerst)
3. M2 + M3 (UI-Flow + Save-Integration)
4. M4 + M5 (Kompatibilität/Edge-Härtung)
5. M6 + M7 + M8 (Test, L10n, QA-Gates)

## Risiken
- Falsche Ownership (Plan versehentlich für falschen User gespeichert, v. a. in Coaching-Kontexten).
- Inkonsistente Übungs-IDs aus Legacy-Sessions führen zu unvollständigen Plänen.
- Doppeltes Speichern bei schnellem Mehrfachklick.
- Gegenmaßnahmen sind in M0, M5 und M3 explizit als Pflicht-Checklist enthalten.
