# Roadmap 2026-03-12 - Backlog Punkt 1
## Thema
Automatische Plan-Auswahl, wenn nur ein Trainingsplan vorhanden ist, ohne unnötige Auswahl-Dialoge.

## Status
- Letzte Aktualisierung: 2026-03-12
- Fortschritt: M1-M4 vollständig umgesetzt
- Launch-Readiness: vollständig launch-ready

## Zielbild
- Wenn genau ein Plan verfügbar ist, wird kein Plan-Picker angezeigt.
- Der Plan wird deterministisch vorausgewählt/übernommen.
- Verhalten ist auf allen Einstiegspunkten konsistent (Startdialog + Plan-Zuweisung im Kalenderflow).

## Ist-Analyse (Code)
- Start-Flow im Profil: `lib/features/profile/presentation/screens/profile_screen.dart` (`_handleStartTraining`, `_TrainingStartDialog`).
- Plan-Auswahlsheet im Kalenderflow: `lib/features/training_plan/presentation/widgets/plan_selection_sheet.dart`.
- Plan-Laden über `trainingPlanRepositoryProvider`.

## Umsetzungsstrategie
- Selektion nicht nur im UI-Widget, sondern zentral im Start-/Selection-Flow entscheiden.
- Bei `plans.length == 1` direkt `onSelect`/`startPlan` ausführen.
- Dialog nur zeigen, wenn mehr als ein Plan vorhanden ist oder eine echte Auswahl nötig ist.

## Meilensteine
### M1 - Entscheidungslogik zentralisieren
- [x] Entscheidungslogik im Start-/Selection-Flow zentralisiert (`ProfileScreen`).
- [x] Timeouts/Fallbacks beibehalten (kein Blocker bei Offline/Timeout).
- [x] Logging für `auto_selected_single_plan` und `dialog_required` ergänzt.

### M2 - Startdialog optimieren
- [x] `_handleStartTraining` lädt verfügbare Pläne robust und setzt Single-Plan als klaren Default.
- [x] Direkter Start ohne Dialog bei exakt 1 Plan umgesetzt.
- [x] Bestehende Pfade (`Freestyle`, geplanter Tagesplan) bleiben funktionsfähig.

### M3 - PlanSelectionSheet (Kalender/Tag-Planung) entschlacken
- [x] Vor `PlanSelectionSheet`: bei genau 1 Plan direkte Zuweisung + Snackbar.
- [x] `PlanSelectionSheet` wird nur bei echter Auswahl angezeigt.
- [x] Edge Case 0 Pläne bleibt stabil (kein Crash, bestehender Fehlerpfad).

### M4 - Regression-Absicherung
- [x] Entscheidungspfad-Tests ergänzt (`test/features/profile/application/training_start_decision_resolver_test.dart`).
- [x] Fall A: 1 Plan -> direkter Startpfad.
- [x] Fall B: >1 Plan -> Dialog bleibt.
- [x] Fall C: 0 Pläne -> Dialog/Fallback bleibt stabil.

## Backend/Datenseite
- Keine Schema-Änderung erforderlich.
- Firestore Rules/Indexes unverändert.

## Qualitäts-Gates vor Launch
- [x] `flutter analyze` (betroffene Dateien) ohne neue Warnungen.
- [x] Betroffene Flow-Tests grün.
- [x] Startlogik 0/1/mehrere Pläne + geplanter Pfad automatisiert abgesichert.

## Risiken
- Startfluss kann bei zu aggressiver Auto-Selektion Freestyle überschreiben.
- Gegenmaßnahme: klare Priorität dokumentieren:
- Geplanter Tagesplan > explizite User-Auswahl > Single-Plan-Autoselect > Freestyle.
