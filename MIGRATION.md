# Migration Notes

- Create a Firestore composite index for `gyms/{gymId}/devices/{deviceId}/sessions` on `userId` equality and `createdAt` descending order.
- Optionally backfill legacy session snapshots that lack a `userId` by setting the field based on the owning user when first read.
