# XP Device Flow

This document outlines the XP credit flow for device-based sessions.

## Troubleshooting: User has 0 XP while others accrue

If a member's XP remains at 0 while others earn points, check the device leaderboard entry in Firestore:

- The document must contain `userId`, `xp`, and `level` fields.
- Missing `userId` prevents write access due to security rules.
- Run `node scripts/repair_leaderboard.js <gymId> <deviceId>` to repair existing entries.
