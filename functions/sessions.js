const functions = require('firebase-functions');
const admin = require('firebase-admin');

const IDLE_TIMEOUT_MINUTES = 60;
const IDLE_TIMEOUT_MS = IDLE_TIMEOUT_MINUTES * 60 * 1000;

function coerceDate(value) {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return null;
}

function resolveEndAt(lastActivity, now) {
  const activity = lastActivity ?? now;
  const candidate = new Date(activity.getTime() + IDLE_TIMEOUT_MS);
  return candidate.getTime() < now.getTime() ? candidate : now;
}

function computeDurationMinutes(startedAt, endAt) {
  if (!startedAt) {
    return 0;
  }
  const ms = Math.max(0, endAt.getTime() - startedAt.getTime());
  return ms / 60000;
}

async function closeSessionDocument(docRef, data, options = {}) {
  const now = options.now instanceof Date ? options.now : new Date();
  const startedAt = coerceDate(data.startedAt) ?? now;
  const lastActivity = coerceDate(data.lastActivityAt) ?? startedAt;
  const summary = typeof data.summary === 'object' && data.summary !== null ? data.summary : {};
  const endAtDate = resolveEndAt(lastActivity, now);
  const normalizedSummary = {
    setCount: Number.isFinite(summary.setCount) ? summary.setCount : 0,
    exerciseCount: Number.isFinite(summary.exerciseCount) ? summary.exerciseCount : 0,
    totalVolume: Number.isFinite(summary.totalVolume) ? summary.totalVolume : 0,
    durationMin: computeDurationMinutes(startedAt, endAtDate),
    prCount: Number.isFinite(summary.prCount) ? summary.prCount : 0,
    prTypes: Array.isArray(summary.prTypes)
      ? summary.prTypes.filter((item) => typeof item === 'string')
      : [],
  };

  await docRef.set(
    {
      status: 'closed',
      endAt: admin.firestore.Timestamp.fromDate(endAtDate),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      summary: normalizedSummary,
    },
    { merge: true }
  );

  return { endAt: endAtDate, summary: normalizedSummary };
}

async function closeQuerySnapshot(docs, options = {}) {
  const results = [];
  for (const doc of docs) {
    const data = doc.data() || {};
    if (options.dryRun) {
      results.push({ id: doc.id, closed: false });
      continue;
    }
    await closeSessionDocument(doc.ref, data, options);
    results.push({ id: doc.id, closed: true });
  }
  return results;
}

const closeIdleSessions = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async () => {
    const now = new Date();
    const cutoff = admin.firestore.Timestamp.fromMillis(now.getTime() - IDLE_TIMEOUT_MS);
    const snap = await admin
      .firestore()
      .collectionGroup('sessions')
      .where('status', '==', 'open')
      .where('lastActivityAt', '<=', cutoff)
      .get();

    if (snap.empty) {
      console.info('closeIdleSessions: no stale sessions');
      return null;
    }

    await closeQuerySnapshot(snap.docs, { now });
    console.info('closeIdleSessions: closed sessions', { count: snap.size });
    return null;
  });

const backfillSessions = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token?.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  const dryRun = Boolean(data?.dryRun);
  const now = data?.now ? new Date(data.now) : new Date();
  const snap = await admin
    .firestore()
    .collectionGroup('sessions')
    .where('status', '==', 'open')
    .get();

  let closed = 0;
  const processed = snap.size;
  if (!dryRun) {
    for (const doc of snap.docs) {
      await closeSessionDocument(doc.ref, doc.data() || {}, { now });
      closed += 1;
    }
  }

  console.info('backfillSessions', { processed, closed, dryRun });
  return { processed, closed, dryRun };
});

const onSessionWrite = functions.firestore
  .document('users/{uid}/sessions/{sessionId}')
  .onWrite(async (change, context) => {
    const before = change.before.exists ? change.before.data() || {} : {};
    const after = change.after.exists ? change.after.data() || {} : {};
    if (!change.after.exists) {
      return null;
    }
    if (before.status === 'closed' || after.status !== 'closed') {
      return null;
    }
    const topic = functions.pubsub.topic('session.closed');
    const payload = {
      userId: context.params.uid,
      sessionId: context.params.sessionId,
      gymId: after.gymId || null,
      setCount: after.summary?.setCount ?? 0,
      durationMin: after.summary?.durationMin ?? 0,
      status: after.status,
    };
    try {
      await topic.publishMessage({ json: payload });
      console.info('session.closed published', payload);
    } catch (err) {
      console.error('session.closed publish failed', err);
    }
    return null;
  });

module.exports = {
  closeIdleSessions,
  backfillSessions,
  onSessionWrite,
  _test: {
    coerceDate,
    resolveEndAt,
    computeDurationMinutes,
    closeSessionDocument,
  },
};
