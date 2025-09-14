---
change_id: GAM-20250914-cardio-history-and-xp-parity
title: Cardio history crash fix, snapshot navigation, and XP parity
branch: fix/cardio-history-and-xp-parity
pr_url: TODO
commit_sha: 1d8cb86782c83b7baa49499b651fdd224c22a34c
app_version: 1.0.0+1
authors: [CodeX]
created_at: 2025-09-14
---

## Prompt (Ziel & Kontext)
History page crashed on cardio logs lacking weight/reps. Cardio navigation and XP awarding differed from strength sessions.

## Umsetzung (dieser PR)
- Made workout log DTOs and models cardio-aware with nullable strength fields and cardio metadata.
- Enabled cardio history and snapshot navigation with steady and interval displays.
- Linked timed cardio saves to XP flow and updated UI feedback.
- Added tests for DTO parsing, snapshot rendering, and cardio XP awarding.

## Ergebnis des PR
Screens: history cardio entries, cardio snapshot modes, XP indicator updates. Known limits: translations for interval headers use generic strings.

## Messplan
- Cardio-XP-Award-Rate
- History-Crash-Rate = 0
- Cap-Treffer
