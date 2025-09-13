---
change_id: GAM-20250913-01
title: Gamification XP Overhaul (Daily/Device/Muscle + Levels)
branch: feature/xp-overhaul-levels
pr_url: TBD
commit_sha: a69e24c8815b2d117bb3c9ead3bcf554ac3d2dcf
app_version: 0.1.0
authors: [CodeX, Daniel]
created_at: 2025-09-13T14:32:07Z
---

## Prompt (Ziel & Kontext)
- Ziel: Daily=1×50, Device=+50/Session (Cap 50/Tag bei isMulti=false), Muscle=+50 primär/+10 sekundär; Level: 1000 XP → XP=0, L+1, Max L30.
- Kontext: Flutter + Firebase; Vergabe serverseitig; Idempotenz & Abuse-Prevention.

## Umsetzung (dieser PR)
- Cloud Function `grantXpForSession` + Marker/Transaktionen
- Datenmodell-Updates (Daily/Device/Muscle docs)
- Provider/UI: Level-Anzeige & Progress
- Remote Config Defaults
- Rules/App Check Verschärfungen
- Telemetrie-Events

## Ergebnis des PR
- Manuelle Tests (Screenshots/Logs)
- Risiken/Guardrails
- Offene Punkte/Follow-ups

## Messplan
- KPIs: Daily-Adoption, Geräte-Cap-Wirksamkeit, Muskel-Progress, Level-Verteilung
- Rollout: RC-Toggle + Staged Rollout (0→5→25→100 %)
