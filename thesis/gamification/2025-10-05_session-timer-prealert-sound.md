# Session Timer – Pre-Alert & End-Sound

## Prompt
```
Prompt für Codex: Session Timer – Pre-Alert & End-Sound (Flutter)
Ziel

Implementiere in der bestehenden Session-Timer-Funktionalität einen kurzen Audio-Hinweis kurz vor Ablauf (Pre-Alert) und den finalen End-Sound bei 0 s. Die Lösung muss plattformübergreifend (Android, iOS, Emulatoren/Simulatoren) funktionieren, geringe Latenz besitzen, robust gegenüber Pausieren/Stoppen sein und keinerlei bestehende Trainings-/Workout-Logik verändern.

Wichtig (Projektregel): Lege zusätzlich eine .md unter thesis/gamification/ an, die Prompt, Ziel/Kontext, Änderungen und Ergebnis dieses PRs dokumentiert (siehe Abschnitt PR & Doku).

Kontext (aktueller Stand)

State/Service: SessionTimerService (ChangeNotifier) mit auswählbaren Presets (60/90/120/150/180 s), Listenern für Tick und Done.

Controller: SessionTimerController zählt via Ticker herunter, stellt ValueNotifier<Duration> remaining und ValueListenable<bool> running.

UI: SessionTimerBar konsumiert den Service, rendert Fortschritt, Start/Stop, ± Buttons und triggert bei 0 s bereits SystemSound.click + Haptik.

Scope: Der Pausen-Timer ist rein lokal; keine Backend-Calls. Es existiert parallel ein separater Workout-Dauer-Timer – den nicht anfassen.

Funktionale Anforderungen

Pre-Alert: Standardmäßig bei 3 Sekunden Restzeit 1× ein kurzer Sound abspielen.

Einmalig pro Countdown-Zyklus; bei Stop/Restart wieder erlauben.

Kein Pre-Alert, wenn Timer mit <3 s gestartet oder vor Erreichen gestoppt wird.

End-Sound: Bei Ablauf (== 0:00) den finalen Sound abspielen (bestehendes SystemSound/Haptik darf bleiben).

Konfigurierbar: preAlertAt als Duration (Default 3s) in SessionTimerService.

Low-Latency & Preload: Audio vorab laden; Playback soll sofort feuern (ohne wahrnehmbare Verzögerung).

Fehlerrobust: Keine Crashes, wenn Asset (noch) fehlt; Logging + stilles Überspringen.

Keine Änderungen an Trainingslogik, XP, Sets etc.

Technische Umsetzung (Vorgaben)
Paketwahl

Verwende audioplayers (aktuelles Stable) mit PlayerMode.lowLatency für kurze SFX. Kein Streaming, kein just_audio nötig.

Asset & Platzierung der .wav

Erstelle Ordner assets/sounds/ im Flutter-Projekt.

Dateiname: session_timer_end.wav (vom Maintainer geliefert).

pubspec.yaml:

flutter:
  assets:
    - assets/sounds/

Hinweis in README: Der Ordner muss die Datei enthalten, sonst wird der Sound übersprungen (Code fängt das ab).

Audio-Service (neu)

Neue Klasse TimerAudioService (z. B. unter lib/src/services/audio/):

Kapselt AudioPlayer (lowLatency), preload des Assets, playPreAlert() und playEnd() Methoden.

Mixing/Focus: iOS per Plugin-Defaults; setze, wenn verfügbar, Category auf ambient (mischt mit anderer Musik). Keine zusätzlichen Android-Permissions erforderlich.

Lifecycle: dispose() sauber implementieren.

Registriere TimerAudioService top-level (z. B. Provider/GetIt) – analog zu den bestehenden Services – oder lazy-instantiate in SessionTimerService (bevorzugt via Injektion, um testbar zu bleiben).

Integration in SessionTimerService

Neue Felder:

Duration preAlertAt = const Duration(seconds: 3);

bool _preAlertFired = false;

Reset _preAlertFired bei startWith(...), bei stop() und wenn der Timer natürlich abläuft.

Im Tick-Handling: Wenn remaining <= preAlertAt && !_preAlertFired && running, dann audio.playPreAlert() und _preAlertFired = true;.

Beim Done-Event: audio.playEnd() (bestehendes SystemSound/Haptik darf bleiben).

UI (SessionTimerBar)

Keine sichtbaren UI-Änderungen erforderlich.

Optional (kleine DX-Hilfe): Tooltip/Info-Icon im i-Dialog erwähnen: „Akustischer Hinweis 3 s vor Ablauf“.

Emulator/Simulator-Hinweise (DX)

Android-Emulator: „Enable audio“ muss aktiv sein.

iOS-Simulator: System-Lautstärke nicht stumm. Silent switch gilt nur für echte Geräte.

Edge Cases

Daueränderung während der Laufzeit: Pre-Alert bezieht sich weiterhin auf die Restzeit; _preAlertFired bleibt korrekt, kein doppeltes Abspielen.

Start mit Restzeit < preAlertAt: kein Pre-Alert.

Timer gestoppt, bevor preAlertAt erreicht: kein Pre-Alert.

Mehrfaches Start/Stop in kurzer Folge: Keine Overlaps – audioplayers Instanz reuse + stop() vor erneutem play.

App im Hintergrund: Kein spezielles Handling nötig (Out-of-Scope).

Tests & QS

Unit: Fake-Ticker/Fake-Time – verifiziere, dass playPreAlert() genau einmal bei <= preAlertAt aufgerufen wird; playEnd() bei 0 s.

Widget Smoke: SessionTimerBar rendert/bedient sich wie zuvor.

Manual:

Start 90 s → Pre-Alert bei 0:03, End-Sound bei 0:00.

Start 2 s → nur End-Sound.

Start 10 s, Stop bei 5 s → kein Sound.

Start 10 s, +/- drücken → weiterhin genau ein Pre-Alert.

Dateien (typisch)

lib/src/services/session_timer/session_timer_service.dart (Erweiterung)

lib/src/services/session_timer/session_timer_controller.dart (nur falls nötig)

Neu: lib/src/services/audio/timer_audio_service.dart

lib/src/widgets/session_timer/session_timer_bar.dart (minimal/gar nicht)

pubspec.yaml (Assets + Dependency)

assets/sounds/ (Ordner, README)

Abnahme-Kriterien (Definition of Done)

Pre-Alert und End-Sound funktionieren deterministisch, ohne spürbare Latenz, ohne Dopplungen.

Build läuft auf Android & iOS & Emulator/Simulator.

Kein Einfluss auf Workout-Timer/Backend.

Code dokumentiert, sauber getestet (mind. Unit-Tests für Trigger-Logik).

Kein zusätzlicher App-Permission-Dialog.

PR & Doku (Gamification-Log)

Branch: codex/session-timer-prealert-sound

PR-Titel: feat(timer): add low-latency pre-alert & end sound

PR-Beschreibung: Kurz Zweck, technische Umsetzung, Tests, DX-Hinweise.

.md anlegen: thesis/gamification/2025-10-05_session-timer-prealert-sound.md

Inhalt: Prompt (dieser Text), Ziel, Kontext, Änderungen (Dateiliste, Kerndiffs), Testplan, offene Punkte/Follow-Ups, Merge-Entscheidung/Outcome.

Hinweis im PR: Maintainer muss die Datei assets/sounds/session_timer_end.wav bereitstellen (3 s), dann flutter pub get und testen.

Wichtig: Was du nicht tun sollst

Keine Änderungen an XP-, Satz-, History- oder Backend-Logik.

Kein neues globales Permission-Handling, keine Notifications.

Kein Vendor-Lock-in über komplexe Audio-Engines.

Auf geht’s. Bitte setze das um, beachte die Abnahme-Kriterien und liefere einen sauberen, review-fertigen PR inkl. der .md-Dokumentation unter thesis/gamification/.
```

## Ziel & Kontext
- Audio-Hinweise kurz vor Ablauf und bei Ende des Session-Timers bereitstellen, ohne die bestehende Workout-Logik zu verändern.
- Sicherstellen, dass die Lösung geringe Latenz bietet, robust gegenüber Benutzerinteraktionen ist und auf allen Zielplattformen funktioniert.

## Änderungen
- **Dateien**
  - `pubspec.yaml`
  - `assets/sounds/README.md`
  - `lib/services/audio/timer_audio_service.dart`
  - `lib/ui/timer/session_timer_service.dart`
  - `test/ui/timer/session_timer_service_test.dart`
  - `README.md`
- **Kerndiffs**
  - Neue Low-Latency-Audioverwaltung für Pre-Alert und End-Sound inklusive Preloading und robustem Fehlerhandling.
  - Erweiterung des SessionTimerService um Pre-Alert-Konfiguration, Zustandsverwaltung und Audio-Integration.
  - Unit-Tests zur Absicherung der Trigger-Logik und Verifikation der Audioaufrufe.
  - Dokumentations-Updates für Asset-Voraussetzungen.

## Testplan
- `flutter test`

## Offene Punkte / Follow-Ups
- Maintainer muss `assets/sounds/session_timer_end.wav` bereitstellen, damit Audio wiedergegeben wird.
- Optionaler UI-Hinweis (Tooltip/Dialog) kann später ergänzt werden.

## Merge-Entscheidung / Outcome
- Bereit für Merge nach Review.
