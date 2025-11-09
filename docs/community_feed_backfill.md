# Community feed backfill runbook

The community feed now stores one deterministic `day_summary` document per user and day. Older `session_summary` documents should be merged into the new structure so that the live ticker only displays daily rollups.

## Preparation

1. Export a service account JSON with read/write access to the production Firestore project.
2. Install dependencies locally:
   ```bash
   npm install firebase-admin@latest
   ```
3. Set the environment variable `GOOGLE_APPLICATION_CREDENTIALS` to the downloaded service account path.

## Backfill script

The following Node.js snippet aggregates legacy feed entries and rewrites them into the new `{dayKey}_{userId}` documents. Save it as `scripts/backfill_day_summaries.mjs` and execute it with `node`.

```js
import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function backfillGym(gymId) {
  const feed = db.collection('gyms').doc(gymId).collection('feed_events');
  const snapshot = await feed.where('type', '==', 'session_summary').get();
  const aggregates = new Map();

  snapshot.forEach((doc) => {
    const data = doc.data();
    const dayKey = data.dayKey || doc.createTime.toDate().toISOString().split('T')[0];
    const userId = data.userId || 'unknown';
    const key = `${dayKey}_${userId}`;
    const entry = aggregates.get(key) ?? {
      refs: [],
      reps: 0,
      volume: 0,
      setCount: 0,
      exerciseCount: 0,
      username: data.username,
      avatarUrl: data.avatarUrl,
    };

    entry.refs.push(doc.ref);
    entry.reps += Number(data.reps ?? 0);
    entry.volume += Number(data.volume ?? 0);
    entry.setCount += Number(data.setCount ?? 0);
    entry.exerciseCount += Number(data.exerciseCount ?? 0) || 1;

    aggregates.set(key, entry);
  });

  for (const [key, entry] of aggregates) {
    const [dayKey, userId] = key.split('_');
    const target = feed.doc(key);
    await db.runTransaction(async (tx) => {
      tx.set(target, {
        type: 'day_summary',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId,
        dayKey,
        username: entry.username,
        avatarUrl: entry.avatarUrl,
        reps: admin.firestore.FieldValue.increment(entry.reps),
        volume: admin.firestore.FieldValue.increment(Number(entry.volume.toFixed(2))),
        sessionCount: admin.firestore.FieldValue.increment(entry.refs.length),
        exerciseCount: admin.firestore.FieldValue.increment(entry.exerciseCount),
        setCount: admin.firestore.FieldValue.increment(entry.setCount),
      }, { merge: true });

      entry.refs.forEach((ref) => tx.update(ref, { type: 'migrated_session', migratedAt: admin.firestore.FieldValue.serverTimestamp() }));
    });
  }
}

async function main() {
  const gyms = await db.collection('gyms').get();
  for (const doc of gyms.docs) {
    console.log(`Backfilling gym ${doc.id}`);
    await backfillGym(doc.id);
  }
  console.log('Backfill complete.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
```

## Verification

1. Spot-check a gym in the Firebase console to confirm a single `day_summary` document exists per `{dayKey}_{userId}`.
2. Ensure legacy `session_summary` documents are tagged with `type: migrated_session` so that clients ignore them.
3. Monitor the live ticker after deployment to confirm only daily summaries appear.

## Rollback

If any issues occur, delete the newly created deterministic documents and restore the original `session_summary` documents from a backup export.
