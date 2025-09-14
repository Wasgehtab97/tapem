---
change_id: GAM-cardio-devices
title: Add Cardio device type
branch: feature/cardio-devices
pr_url: PR_URL_PLACEHOLDER
commit_sha: 759ce9c51a8f6f818cd2da81cecbbb1630ae1eee
app_version: 0.1.0
authors: ["CodeX"]
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
Neuer Gerätetyp "Cardio" mit Geschwindigkeit und Zeit.

## Umsetzung (dieser PR)
- Gerätemodell und DTO um `isCardio` erweitert
- Admin-Dialog mit "Cardio?"-Schalter
- Provider, Drafts und Snapshot unterstützen Speed/Duration
- UI SetCard & History zeigen Cardio-Sets

## Ergebnis des PR
Screenshots TODO. Cardio-Eingabe gespeichert, Historie zeigt Speed/Duration. Bekannte Limits: Eingabezeit nur als Sekunden, fehlende komplette Validierungen.

## Messplan
- Adoption Cardio-Geräte
- Fehlerquote Validierung
- Anteil Cardio an Sessions
Beobachtungsfenster: 4 Wochen.
