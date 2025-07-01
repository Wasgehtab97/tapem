# Provider Struktur

Dieses Dokument gibt einen kurzen Überblick über die wichtigsten Provider im Projekt und ihre Aufgaben. Das erleichtert neuen Entwicklern den Einstieg in das State‑Management.

| Provider | Aufgabe |
|----------|---------|
| `AuthProvider` | Hält Informationen zum aktuell angemeldeten Nutzer und zum ausgewählten Gym. |
| `DeviceProvider` | Lädt die verfügbaren Geräte eines Gyms und verwaltet Gerätestate während einer Trainingseinheit. |
| `ExerciseProvider` | Liefert zu einem Gerät die zugehörigen Übungen. |
| `TrainingPlanProvider` | Zuständig für Erstellen, Bearbeiten und Speichern von Trainingsplänen. Speichert die aktuell geöffnete Planinstanz und verwaltet Laden/Speichern über das Repository. Bietet Funktionen zum Kopieren ganzer Wochen oder einzelner Trainingstage. |
| `GymProvider` | Enthält Metadaten zum Gym, z.B. Branding und verfügbare Geräte. |
| `ProfileProvider` | Lädt die Trainingstage eines Nutzers für die Profilansicht. |
| `ReportProvider` | Erstellt Auswertungen und Statistiken für Reports. |

Die Provider werden in `main.dart` bzw. in den jeweiligen Screens via `Provider` oder `Consumer` eingebunden. Durch dieses zentrale State‑Management können UI-Komponenten auf Änderungen reagieren, ohne selbst Daten laden zu müssen.