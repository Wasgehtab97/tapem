## Backlog

1. **Automatische Plan-Auswahl**
   - Wenn nur ein Trainingsplan vorhanden ist, sollte dieser automatisch im Startdialog gewählt werden.
   - Verorte Logik in `lib/features/training_plan/presentation/widgets/plan_selection_sheet.dart` oder `lib/features/profile/presentation/screens/profile_screen.dart`.
   - Vermeide den unnötigen Auswahl-Dialog in `PlanSelectionSheet`.

2. **Zeitplanung für Trainingspläne**
   - Trainingspläne an Wochentagen / Rhythmus (z. B. alle X Tage) zuordnen.
   - Beim App-Start den entsprechenden Plan automatisch als Default laden, ohne manuelle Auswahl.
   - Mögliche Dateien: `lib/features/training_plan/domain/entities/schedule.dart`, `lib/features/training_plan/presentation/screens/plan_overview_screen.dart`.

3. **Gewichtseingabe‑Modal**
   - Bei Tap auf Gewichtseingabe ein Modal öffnen, das den Wert des vorherigen Trainings zeigt (falls vorhanden, sonst 0).
   - Links/rechts +/- Buttons zum Anpassen des Gewichts.
   - Gewicht pro Übung speichern; Standardwert 2.5 kg verwenden, falls keine Historie vorhanden.
   - Schau in `lib/features/training_plan/presentation/widgets/exercise_row.dart` (oder ähnliches) nach der aktuellen Eingabebehandlung.

4. **Satzanzahl übernehmen**
   - Standardmäßig werden 3 Sätze angezeigt.
   - Wenn beim letzten Mal in derselben Trainingsplan-Session 5 Sätze ausgeführt wurden, sollen beim nächsten Start ebenfalls 5 angezeigt werden.
   - Diese Einstellung gehört zum Trainingsplan, nicht zur einzelnen Übung.
   - Dateien: `lib/features/training_plan/domain/models/plan.dart`, `lib/features/training_plan/presentation/screens/plan_detail_screen.dart`.
