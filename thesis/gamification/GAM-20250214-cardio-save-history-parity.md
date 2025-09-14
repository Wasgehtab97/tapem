---
change_id: GAM-20250214-cardio-save-history-parity
title: Cardio save/history parity
branch: fix/cardio-devicepage-save-history-parity
pr_url: TBD
commit_sha: 5426176b9b6dbe2526a88e4f406aa8f1d3ea9c06
app_version: 1.0.0+1
authors: CodeX
created_at: 2025-02-14
---

## Prompt (Ziel & Kontext)
Parität für das Speichern von Cardio-Sessions inklusive Snapshot & Log. Trainingsdetails sollen Cardio ohne Fehler laden.

## Umsetzung (dieser PR)
- Lifecycle-Fix für Devicepage ohne Provider-Lookup im dispose.
- Cardio-aware Mapping und Repository; Session-Model erweitert.
- Cardio-SessionCard in TrainingDetails.
- Firestore-Rules erlauben Cardio-Felder.
- Tests für Cardio-Mapping und Repository.

## Ergebnis des PR
_Screenshots der Devicepage, Save-Flow, Right-Swipe und Trainingsdetails werden nachgereicht._

## Messplan
- Crash-Rate Devicepage
- Fehlerquote loadSessions
- Anteil Cardio-Saves
