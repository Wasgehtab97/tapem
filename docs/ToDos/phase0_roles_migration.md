# Phase 0 Rollenmigration (member/gymowner/admin)

Stand: 2026-02-15

## Ziel

Legacy-Rollen auf den finalen Contract mappen:
- `global_admin` -> `admin`
- `gym_admin` -> `gymowner`

Betroffene Ebenen:
- Firestore: `users/{uid}.role`
- Firestore: `gyms/{gymId}/users/{uid}.role`
- Firebase Auth Custom Claims: `role`

## Script

Pfad:
- `functions/scripts/migrate_roles_phase0.js`

Dry-run:
```bash
KEY_FILE=./scripts/admin.json node functions/scripts/migrate_roles_phase0.js
```

Apply:
```bash
KEY_FILE=./scripts/admin.json node functions/scripts/migrate_roles_phase0.js --apply
```

## Rollout-Reihenfolge

1. Deploy Functions + Rules + App (dieser Phase-0-Stand).
2. Dry-run der Migration ausführen und Zählwerte prüfen.
3. Apply ausführen.
4. Betroffene User neu einloggen lassen (Claims-Refresh erzwingen).
5. Smoke-Tests:
- GymOwner kann Owner/Admin-Flows im eigenen Gym nutzen.
- App-Admin kann globale Admin-Funktionen nutzen.
- Member hat keinen Zugriff auf Admin-Routen.

## Abnahmekriterien

- Keine verbleibenden `global_admin`/`gym_admin` Rollen in Firestore/Claims.
- Keine Permission-Divergenzen zwischen App-Routing und Firestore Rules.
- Keine Blocker in Kernflüssen (Admin Dashboard, Remove User, Geräte/Deals/Challenges).
