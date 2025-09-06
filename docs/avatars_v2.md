# Avatars V2

## Collections

### `gyms/{gymId}/avatarCatalog/{avatarId}`
- `name` (string)
- `description` (string, optional)
- `assetStoragePath` (string) or `assetUrl` (string)
- `isActive` (bool)
- `tier` (string enum: `common`|`rare`|`legendary`, optional)
- `unlock` (map)
  - `type` (`xp`|`challenge`|`event`|`manual`)
  - `params` (map, free-form)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)
- `createdBy` (uid)
- `updatedBy` (uid)

### `catalogAvatarsGlobal/{avatarId}`
- same fields as above

### `users/{uid}/avatarsOwned/{avatarId}`
- `source` ("gym:{gymId}" | "global")
- `unlockedAt` (timestamp)
- `reason` (string)
- `by` ("system"|adminId)
- `grantHash` (string)

### `users/{uid}`
- `equippedAvatarRef` (string, path to catalog entry)

## Indices
- `avatarCatalog` collection group: `isActive` ASC, `tier` ASC
- `catalogAvatarsGlobal` collection group: `isActive` ASC, `tier` ASC

## Flags
| Flag | Default |
|------|---------|
| `avatars_v2_enabled` | false |
| `avatars_v2_migration_on` | false |
| `avatars_v2_images_cdn` | false |

## Read Rights
- Gym catalog readable only for members of the gym
- Global catalog readable for authenticated users
- Inventory readable only by its owner

## Unlock Examples
- `{ "type": "xp", "params": { "xpThreshold": 1000 } }`
- `{ "type": "challenge", "params": { "challengeId": "c1" } }`
- `{ "type": "event", "params": { "eventId": "e1", "window": "2024-01" } }`

## Roadmap
1. **Phase 2** – Inventory & Equip
2. **Phase 3** – Grant Pipeline
3. **Phase 4** – Rules & Functions Tests
4. **Phase 5** – Migration V1→V2
5. **Phase 6** – Telemetry & Rollout

## Phase 2 Flows

### Inventory Read (Client)
- Pfad: `users/{uid}/avatarsOwned/{avatarId}`
- Provider lädt einmalig alle Doc-IDs → Menge der `avatarId`
- Nur bei gesetztem Flag `avatars_v2_enabled`
- Cache im Speicher, Invalidation bei Sign-Out / Gym-Wechsel

### Equip (Owner-Write)
- Feld: `users/{uid}.equippedAvatarRef`
- Client validiert:
  - Referenz zeigt auf existierenden Katalogeintrag
  - `avatarId` in `avatarsOwned`
  - Bei Gym-Avataren: Besitzer ist Mitglied des Gyms und Quelle passt
- Schreibvorgang: optimistisches Update, bei Fehler Rollback
- Fehlercodes: `not_owned`, `invalid_ref`, `cross_gym_forbidden`, `not_member`, `write_denied`, `unknown`

### Public Mirror (Cloud Function)
- Trigger: `onWrite` auf `users/{uid}.equippedAvatarRef`
- Ziel: `publicProfiles/{uid}`
  - `equippedAvatarRef`
  - `resolvedAvatarUrl` (optional)
- Auflösung `resolvedAvatarUrl`:
  - falls `assetUrl` vorhanden → direkt
  - falls nur `assetStoragePath` und kein CDN-Mechanismus → leer (Annahme)

### Fehler-/Konfliktfälle
- Equip von nicht-owned Avatar → `not_owned`
- Cross-Gym (Quelle ≠ Ziel-Gym) → `cross_gym_forbidden`
- Ungültige Referenz → `invalid_ref`
