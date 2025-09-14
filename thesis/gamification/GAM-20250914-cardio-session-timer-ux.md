---
change_id: GAM-20250914-cardio-session-timer-ux
title: "Cardio Session Timer UX"
branch: feature/cardio-session-timer-ux
pr_url: TBA
commit_sha: e9ae7c4627c58f0f84be760c69dfc2907b8f0272
app_version: 1.0.0+1
authors: [CodeX]
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
- Cardio-SessionCard besitzt nur ein Geschwindigkeitsfeld.
- Zeiten werden über einen Start/Stop-Timer gemessen; Zeit optional.
- Persistenz, Historie und Telemetrie respektieren speedKmH und optionale durationSec.

## Umsetzung (dieser PR)
- UI: Timer-Button in Cardio-SetCard, automatisches Stoppen beim Speichern.
- Provider: Validierung nur auf Speed; optionales durationSec, Auto-Stop.
- Persistenz: durationSec nur bei >0 gespeichert; Historie blendet fehlende Zeiten aus.
- Telemetrie: cardio_timer_started/stopped und Session-Events mit Speed/Duration.
- Rules: Tests für optionale durationSec.

## Ergebnis des PR
- Screenshots: running/stopped (siehe Assets).
- Bekannte Limitierungen: keine explizite Reset-Animation.

## Messplan
- Timer-Adoption
- Anteil Speed-only Sets
- Validierungsfehler-Rate
- Beobachtungsfenster: 4 Wochen nach Release
