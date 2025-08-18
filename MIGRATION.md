# Migration Notes

- Create a Firestore composite index for `gyms/{gymId}/devices/{deviceId}/sessions` on `userId` equality and `createdAt` descending order.
- Backfill existing session snapshots without `userId` by setting the field based on owning user when first read.
