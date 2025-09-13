---
change_id: GAM-20250913-02
title: Gamification XP Overhaul Server + Daily Ring
branch: feature/xp-overhaul-daily-ring
pr_url: TBD
commit_sha: c9990cdb37d84ac646f5d9a37474b71ff0f3c2a2
app_version: 0.1.0
authors: [CodeX]
created_at: 2025-09-13T00:00:00Z
---

## Prompt (Ziel & Kontext)
- Serverseitige XP-Vergabe und Daily-Ring im UI.
- Konsistentes Levelsystem (1-30, 1000 XP pro Level).

## Umsetzung (dieser PR)
- Daily-XP Fortschrittsring um Avatar auf Profilseite.
- Theme-Extension für Ringfarben und Strichstärke.
- Provider berechnet Daily-Level & Fortschritt aus Stats-Daten.
- Unit-Tests für LevelService und Provider.

## Ergebnis des PR
- Ring visualisiert Daily-Fortschritt; L30 zeigt "MAX".
- Tests hinzugefügt (Automatisierung lokal nicht ausgeführt).
- Risiken: fehlende umfassende Backend-Anbindung, fehlende Emulator-Tests.

## Messplan
- KPI: Anteil Nutzer mit täglichem XP-Zuwachs.
- Rollout: via Remote Config schrittweise aktivieren.
