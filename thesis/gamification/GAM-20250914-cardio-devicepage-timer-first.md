---
change_id: GAM-20250914-cardio-devicepage-timer-first
title: Cardio devicepage timer-first flow
branch: feature/cardio-devicepage-timer-first
pr_url: TBD
commit_sha: 264940c12a60f9ac5a68c854cabd4d399598cc2c
app_version: TBD
authors: CodeX
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
Kurzbeschreibung der Spezifikation für Timer-first Cardio-Devicepage.

## Umsetzung (dieser PR)
- Cardio-Devicepage zeigt nur eine SetCard mit Timer.
- Add-Set-Button für Cardio-Geräte entfernt.
- Timer-Stopp öffnet Dialog zur Eingabe der Geschwindigkeit.

## Ergebnis des PR
_Bitte Screenshots der Zustände idle/running/stopped sowie Popup und History hier einfügen._

## Messplan
- Adoption der Intervalle vs. Steady
- Fehlerrate bei Eingaben
- Speicherrate der Cardio-Sessions
- Beobachtungsfenster: 2 Wochen nach Rollout
- Rollout: sofort, ohne Feature-Flag
