---
change_id: cardio-completion
title: "Cardio completion"
branch: feature/cardio-completion
pr_url: TBD
commit_sha: 0b4e120bcd70c8aa8e26e47433649c1dd486059a
app_version: TBD
authors: CodeX
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
Abschluss der Cardio-Eingabe mit Geschwindigkeit in km/h und Dauer im Format hh:mm:ss inklusive Validierung, Persistenz und Historie.

## Umsetzung (dieser PR)
- UI: Maskierte hh:mm:ss-Eingabe und Geschwindigkeitsvalidierung.
- Provider/Drafts: Validierungslogik mit Remote-Config-Grenzen.
- Repo/DTO/Mapper: speedKmH und durationSec Round-Trip.
- Historie: Anzeige von Zeiten als hh:mm:ss.
- Telemetrie: Erweiterte SAVE_START- und LOGS_STORED-Events um Cardio-Daten.
- Rules: Firestore erlaubt neue Felder speedKmH und durationSec.

## Ergebnis des PR
- *Screenshot placeholder*
- *Log snippet placeholder*
- Bekannte Limitierungen: keine.
- Risiken/Guardrails: RC-Defaults sichern Grenzwerte.

## Messplan
- KPIs: Cardio-Adoption, Validierungsfehler-Rate, Persistenz-Erfolgsquote.
- Beobachtungsfenster: 2 Wochen nach Rollout.
- Rollout: ohne Feature-Flag, RC zur Feinsteuerung.
