# Roadmap 2026-03-12 - Backlog Punkt 3
## Thema
Overlay-Tastatur umbauen: `+/-` für aktuelles Feld (`kg`/`wdh`) statt redundantes Satz-`+`.

## Status
- Letzte Aktualisierung: 2026-03-12
- Fortschritt: M1-M5 vollständig umgesetzt
- Launch-Readiness: vollständig launch-ready

## Zielbild
- Rechte Aktionsspalte hat 3 Reihen mit je 2 Buttons.
- Reihe 2: `-` und `+` ändern das aktuell fokussierte Feld um `-1/+1`.
- Reihe 3: links Copy (vorheriger Satz), rechts Keyboard schließen.
- Kein redundanter "Set hinzufügen"-Button mehr in der Overlay-Tastatur.

## Ist-Analyse (Code)
- Keypad UI + Action Rail: `lib/ui/numeric_keypad/overlay_numeric_keypad.dart`.
- Aktuell im Default-Rail: `back`, `next`, `addSet`, `copy`, `hide`.
- Fokus-/Feldkontext liegt in `DeviceProvider` (`focusedIndex`, `focusedField`, `focusedDropIndex`).

## Umsetzungsstrategie
- Action-Rail nicht "implizit" über wide/square-Mischung belassen, sondern für den Default-Modus explizit als 3x2-Matrix rendern.
- Wertanpassung über zentrale Helper-Methode, die aktuellen Fokus aus `DeviceProvider` nutzt.
- Add-Set-Action im Keypad entfernen; Set-Hinzufügen bleibt über `+ Set hinzufügen` in der Card.

## Meilensteine
### M1 - Rail-Layout explizit machen
- [x] In `_ActionRailCompact` Default-Actions auf exakt 6 Slots gemappt.
- [x] Reihe 1: `back`, `next`.
- [x] Reihe 2: `minus`, `plus`.
- [x] Reihe 3: `copy`, `hide`.
- [x] "Wide Hide"-Sonderfall im Default-Modus entfernt.

### M2 - +/- Fachlogik implementieren
- [x] Methode `_adjustFocusedValue(context, controller, delta)` ergänzt.
- [x] Aktives Feld über `DeviceProvider.focusedField` ausgelesen.
- [x] Parsing robust für `,` und `.` umgesetzt.
- [x] Bei `kg`/`dropWeight`: Dezimalwerte erlaubt, Schrittweite `1.0`.
- [x] Bei `wdh`/`dropReps`: Ganzzahl, Untergrenze `0`.
- [x] Controller-Text und Provider-State synchron aktualisiert.

### M3 - Copy/Hide-Reihenfolge anpassen
- [x] Copy-Button nach Reihe 3 links verschoben.
- [x] Hide-Button auf Reihe 3 rechts gesetzt.
- [x] Navigation (`back/next`) unverändert belassen.

### M4 - Semantik, A11y und Telemetrie
- [x] Semantics-Labels für `increase/decrease` genutzt.
- [x] Event-Logs ergänzt (`OVERLAY_ADJUST_PLUS`, `OVERLAY_ADJUST_MINUS`).
- [x] Haptik-Pfad unverändert beibehalten.

### M5 - Tests + visuelle Verifikation
- [x] Widget-Test für Action-Reihenfolge (Icon-Layout) hinzugefügt.
- [x] Logik-Tests für `+/-` auf `kg`, `wdh`, Drop-Felder hinzugefügt.
- [x] Zusätzliche Verifikation per Overflow-Tests (kompakt + landscape) ergänzt.

## Backend/Datenseite
- Keine Backend-Änderungen erforderlich.
- Persistenz läuft weiterhin über bestehende `updateSet/updateDrop`-Pfade.

## Qualitäts-Gates vor Launch
- [x] `flutter analyze` grün.
- [x] Relevante Keypad-/Workout-Tests grün.
- [x] Kein Overflow im Landscape/kleinen Geräten (Widget-Tests).
- [x] Keine Regression bei Fokus-/Navigationspfaden (bestehender Workout-Flow-Test grün).

## Risiken
- Parsing-Fehler bei lokalen Dezimaltrennzeichen.
- Gegenmaßnahme: einheitliche Parsing-/Formatting-Helfer und Tests für `,`/`.`.
