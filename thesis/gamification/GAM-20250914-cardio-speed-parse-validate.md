---
change_id: GAM-20250914-cardio-speed-parse-validate
title: "Cardio Speed Parsing & Validation Hotfix"
branch: hotfix/cardio-speed-accept-numeric
pr_url: TBA
commit_sha: 400d7b9ca2b6e42a063ca41123bc3863e470a24b
app_version: 1.0.0+1
authors: [CodeX]
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
- Cardio-Speed-Eingaben sollen als km/h interpretiert werden.
- Validierung: > 0 und ≤ Remote-Config-Max (Fallback 40).
- Dauer optional; Speed ist Pflicht.

## Umsetzung (dieser PR)
- Lenientes Parsing (Komma/Punkt, Whitespace, führende Nullen) für Speed.
- RC-Fallback und Validierung in Provider & UI.
- Auto-Blur des Speed-Felds und Timer-Stop vor dem Speichern.
- Persistenz: speedKmH immer, durationSec nur wenn >0.

## Ergebnis des PR
- Speed-only-Cardio-Sets speicherbar ohne Fehl-Snackbar.
- Logs/Snapshots enthalten numerisches speedKmH.
- Screenshots: n/a.

## Messplan
- Fehlerquote Parsing/Validierung.
- Anteil Speed-only-Sets.
- Beobachtung: 4 Wochen nach Release.
