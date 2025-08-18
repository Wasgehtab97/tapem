# Migration Notes

- Create a Firestore composite index for `gyms/{gymId}/devices/{deviceId}/sessions` on `userId` equality and `createdAt` descending order.
- Optionally backfill legacy session snapshots that lack a `userId` by setting the field based on the owning user when first read.

- Neue Nutzer werden beim ersten Zugriff automatisch unter `gyms/{gymId}/users/{uid}` mit `role: 'member'` registriert.
- Bei `permission-denied` gibt es einen einmaligen Retry nach Membership-Sicherung.
- Sessions sind owner-basiert geregelt; Abfragen scopen auf `userId`.
