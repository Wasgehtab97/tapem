---
change_id: GAM-20250914-cardio-runner-ui-rebuild
title: Cardio Devicepage Runner UI Rebuild
branch: feature/cardio-devicepage-runner-ui
pr_url: TODO
commit_sha: 7327c34ba137caaeb2f959dd387a15c715fa498a
app_version: TODO
authors: CodeX
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
Rebuild the cardio device page with a large timer and play/pause button. Saving a paused timer persists a timed cardio session.

## Umsetzung (dieser PR)
- Introduced `CardioTimerProvider` with idle→running→stopped state machine.
- Added `CardioRunner` widget showing big timer, play/pause button, and save flow.
- Added simple persistence for cardio sessions with `mode: "timed"` and `durationSec`.
- Localizations for timer labels.
- Firestore rules updated to accept new fields.

## Ergebnis des PR
Screenshots pending.

## Messplan
- cardio_session_saved events count
- average duration
- save/abort ratio
