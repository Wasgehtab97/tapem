---
change_id: GAM-20250914-cardio-parity-header-swipe-cap
title: Cardio: Header-Buttons, Right-Swipe to Snapshot & 1-per-Day Save Cap
branch: feature/cardio-parity-header-swipe-cap
pr_url: TBD
commit_sha: 1bb876424b8905c7fe0aa57db0cf6c24447abe5c
app_version: 1.0.0
authors: CodeX
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
Cardio-Geräte erhalten Header-Parität mit History/XP/Feedback, Right-Swipe zur letzten Snapshot-Session und einen Save-Cap von einer Session pro Gerät und Tag.

## Umsetzung (dieser PR)
- Header-Buttons für Cardio-Geräte wie bei Strength.
- Right-Swipe in der Cardio-Devicepage öffnet den letzten Snapshot.
- Cap-Guard blockiert mehrere Cardio-Saves pro Tag (Client-Check).
- Repositories/Provider/Rules angepasst; Telemetrie für Cap-Block.

## Ergebnis des PR
Screens zeigen neue Header-Buttons, Swipe-Navigation und Cap-Hinweis in der Cardio-Devicepage sowie Einträge in den Trainingsdetails.

## Messplan
- Anteil Cardio-Saves.
- Rate cardio_cap_blocked.
- Fehler/Crashes.
