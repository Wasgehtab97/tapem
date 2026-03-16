# Roadmap 2026-03-12 - Backlog Punkt 5
## Thema
Workout-Header stabilisieren (kein Rest-Timer-Overflow) und Test-Suite für diesen Bereich robust machen.

## Zielbild
- Kein `RenderFlex overflow` mehr im Workout-Header durch den globalen Rest-Timer.
- Header bleibt visuell stabil bei aktivem Globaltimer + Settimer.
- Relevante Widget-Tests laufen sauber.

## Meilensteine
### M1 - Header-Layout robust machen
- [x] Rest-Timer-Breite im Header angepasst (`_headerRestTimerWidth: 80 -> 96`).
- [x] Header-Alignment stabil gehalten (kein zusätzlicher Shift, bestehende `FittedBox`-Strategie bleibt erhalten).

### M2 - Test-Setup bereinigen
- [x] `set_card_test` auf aktuelle Riverpod-Architektur umgestellt (`ProviderScope` + Overrides).
- [x] `session_rest_timer_test` ebenfalls auf Riverpod-Overrides umgestellt; Provider-Type-Fehler beseitigt.
- [x] Veraltete Assertions/Finder in beiden Tests auf aktuellen UI-/State-Pfad angepasst.

### M3 - Regression absichern
- [x] Relevante Tests grün:
- [x] `workout_day_screen_test.dart`
- [x] `set_card_test.dart`
- [x] `session_rest_timer_test.dart`
- [x] `flutter analyze` für geänderte Files ohne Warnungen/Errors.

## Qualitäts-Gates vor Launch
- [x] Header-Overflow reproduzierbar beseitigt.
- [x] Tests grün und Roadmap vollständig aktualisiert.

## Status
- [x] Roadmap vollständig umgesetzt und launch-ready.
