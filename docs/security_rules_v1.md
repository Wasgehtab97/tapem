# Security Rules v1

## Trust boundary
Client applications are untrusted. All critical checks are enforced via Firestore
and Storage rules. Server-side processes (e.g. admin tooling) operate with
privileged credentials.

## Firestore
- **Cross-gym isolation:** access to `/gyms/{gymId}/**` requires membership in
  the targeted gym. Device reads no longer allow generic signed-in access.
- **Membership lifecycle:** documents under `/gyms/{gymId}/users/{userId}` can
  only be created, updated or deleted by gym admins. Members may read membership
  data for their gym but cannot join or change roles themselves.
- **Training plans:** read and write access requires membership in the gym and
  either admin privileges or `createdBy == uid`.
- **Feedback:** members may create feedback; only admins can read or modify
  entries.
- **Leaderboard:** writes require `userId` to match the path. TODO: move writes
  to Cloud Functions.
- **Gym documents:** considered public. Public fields are `name`, `code`, and
  `logoUrl`.
- Global fallback denies all other access.

## Cloud Storage
- Path structure: `feedback/{gymId}/{userId}/{file}`. Gym ID and owner UID are
  encoded in the path to allow rule evaluation.
- Authenticated access only. Reads and writes are restricted to the owner or an
  admin of the corresponding gym.
- Only images (`image/*`) up to 5 MB are accepted. Directory listing is
  disabled.
- Download tokens are not exposed; files are accessed only in authenticated
  contexts.

## Known TODOs
- Leaderboard writes should move to server-side functions.
- Project-wide App Check enforcement to be enabled separately.
