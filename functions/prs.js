const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

const xpEngine = require('./xp_engine');

function computeEpleyOneRepMax(weight, reps) {
  if (!Number.isFinite(weight) || weight <= 0) {
    return null;
  }
  if (!Number.isFinite(reps) || reps <= 0) {
    return null;
  }
  const value = weight * (1 + reps / 30);
  return Math.round(value * 100) / 100;
}

function toNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return null;
}

function normalizeLogEntry(data) {
  const deviceId = typeof data.deviceId === 'string' && data.deviceId.trim() !== '' ? data.deviceId.trim() : null;
  const exerciseId = typeof data.exerciseId === 'string' && data.exerciseId.trim() !== '' ? data.exerciseId.trim() : null;
  const reps = toNumber(data.reps);
  const weight = toNumber(data.weight ?? data.weightKg);
  const isBodyweight = data.isBodyweight === true;
  const drops = [];
  if (Array.isArray(data.drops)) {
    for (const entry of data.drops) {
      if (!entry || typeof entry !== 'object') {
        continue;
      }
      const dropWeight = toNumber(entry.kg ?? entry.weight);
      const dropReps = toNumber(entry.reps);
      if (dropWeight && dropWeight > 0 && dropReps && dropReps > 0) {
        drops.push({ weight: dropWeight, reps: dropReps });
      }
    }
  }
  if (drops.length === 0) {
    const dropWeight = toNumber(data.dropWeightKg ?? data.dropWeight);
    const dropReps = toNumber(data.dropReps);
    if (dropWeight && dropWeight > 0 && dropReps && dropReps > 0) {
      drops.push({ weight: dropWeight, reps: dropReps });
    }
  }
  const setEntries = [];
  if (weight && weight > 0 && reps && reps > 0 && !isBodyweight) {
    setEntries.push({ weight, reps });
  }
  for (const drop of drops) {
    setEntries.push({ weight: drop.weight, reps: drop.reps });
  }
  let sessionVolume = 0;
  let sessionBestE1rm = 0;
  for (const set of setEntries) {
    sessionVolume += set.weight * set.reps;
    const est = computeEpleyOneRepMax(set.weight, set.reps);
    if (est && est > sessionBestE1rm) {
      sessionBestE1rm = est;
    }
  }

  return {
    deviceId,
    exerciseId,
    hasMainSet: Boolean(weight && weight > 0 && reps && reps > 0 && !isBodyweight),
    sessionVolume,
    sessionBestE1rm,
  };
}

function collectSessionMetrics(logDocs) {
  const perExercise = new Map();
  const deviceIds = new Set();
  const exerciseIds = new Set();

  for (const doc of logDocs) {
    const normalized = normalizeLogEntry(doc.data());
    if (!normalized) {
      continue;
    }
    const { deviceId, exerciseId, sessionVolume, sessionBestE1rm } = normalized;
    if (deviceId) {
      deviceIds.add(deviceId);
    }
    if (exerciseId) {
      exerciseIds.add(exerciseId);
    }
    const key = exerciseId || deviceId;
    if (!key) {
      continue;
    }
    const existing = perExercise.get(key) || {
      deviceId: deviceId || null,
      exerciseId: exerciseId || null,
      volume: 0,
      bestE1rm: 0,
    };
    existing.deviceId = existing.deviceId || deviceId || null;
    existing.exerciseId = existing.exerciseId || exerciseId || null;
    existing.volume += sessionVolume;
    if (sessionBestE1rm > existing.bestE1rm) {
      existing.bestE1rm = sessionBestE1rm;
    }
    perExercise.set(key, existing);
  }

  return {
    perExercise,
    deviceIds,
    exerciseIds,
  };
}

function deterministicPrId({ userId, sessionId, type, scope }) {
  const raw = [userId, sessionId, type, scope].filter(Boolean).join('|');
  return crypto.createHash('sha1').update(raw).digest('hex');
}

async function hasHistoricalUsage({ db, userId, sessionId, field, value, limit = 5 }) {
  if (!value) {
    return false;
  }
  const snap = await db
    .collectionGroup('logs')
    .where('userId', '==', userId)
    .where(field, '==', value)
    .limit(limit)
    .get();
  for (const doc of snap.docs) {
    if (doc.data().sessionId !== sessionId) {
      return true;
    }
  }
  return false;
}

async function getPreviousBest({ eventsCol, type, exerciseId, deviceId, sessionId }) {
  let query = eventsCol.where('type', '==', type);
  if (exerciseId) {
    query = query.where('exerciseId', '==', exerciseId);
  }
  if (deviceId) {
    query = query.where('deviceId', '==', deviceId);
  }
  const snap = await query.orderBy('occurredAt', 'desc').limit(5).get();
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.sessionId === sessionId) {
      continue;
    }
    if (typeof data.value === 'number') {
      return data.value;
    }
  }
  return null;
}

function buildBaseEvent({ sessionId, occurredAt, type }) {
  return {
    sessionId,
    occurredAt,
    type,
    confidence: 1,
  };
}

async function handleSessionClosed(message) {
  const userId = message?.userId;
  const sessionId = message?.sessionId;
  if (!userId || !sessionId) {
    functions.logger.warn('pr_pipeline: missing identifiers', message);
    return { created: 0, total: 0 };
  }
  const gymId = message?.gymId || null;
  const db = admin.firestore();
  const sessionRef = db.collection('users').doc(userId).collection('sessions').doc(sessionId);
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) {
    functions.logger.warn('pr_pipeline: missing session doc', { userId, sessionId });
    return { created: 0, total: 0 };
  }
  const sessionData = sessionSnap.data() || {};
  let occurredAt = admin.firestore.Timestamp.now();
  if (sessionData.endAt instanceof admin.firestore.Timestamp) {
    occurredAt = sessionData.endAt;
  } else if (sessionData.updatedAt instanceof admin.firestore.Timestamp) {
    occurredAt = sessionData.updatedAt;
  }

  const logsSnap = await db
    .collectionGroup('logs')
    .where('sessionId', '==', sessionId)
    .where('userId', '==', userId)
    .get();
  const relevantLogs = logsSnap.docs.filter((doc) => {
    if (!gymId) {
      return true;
    }
    return doc.ref.path.includes(`/gyms/${gymId}/`);
  });

  const metrics = collectSessionMetrics(relevantLogs);
  const userRef = sessionRef.parent?.parent;
  if (!userRef) {
    functions.logger.warn('pr_pipeline: unable to resolve user reference', { userId, sessionId });
    return { created: 0, total: 0 };
  }
  const eventsCol = userRef.collection('prEvents');
  const batch = db.batch();
  const createdEvents = [];

  for (const deviceId of metrics.deviceIds) {
    const scope = `device:${deviceId}`;
    const prId = deterministicPrId({ userId, sessionId, type: 'first_device', scope });
    const eventRef = eventsCol.doc(prId);
    const existing = await eventRef.get();
    if (existing.exists) {
      continue;
    }
    const hadHistory = await hasHistoricalUsage({ db, userId, sessionId, field: 'deviceId', value: deviceId });
    if (hadHistory) {
      continue;
    }
    const event = buildBaseEvent({ sessionId, occurredAt, type: 'first_device' });
    event.deviceId = deviceId;
    event.value = 1;
    event.previousBest = 0;
    event.delta = 1;
    event.unit = 'count';
    batch.set(eventRef, event, { merge: true });
    createdEvents.push({ id: prId, type: 'first_device', deviceId });
    functions.logger.info('pr_detected', {
      userId,
      sessionId,
      type: 'first_device',
      deviceId,
    });
  }

  for (const exerciseId of metrics.exerciseIds) {
    const scope = `exercise:${exerciseId}`;
    const prId = deterministicPrId({ userId, sessionId, type: 'first_exercise', scope });
    const eventRef = eventsCol.doc(prId);
    const existing = await eventRef.get();
    if (existing.exists) {
      continue;
    }
    const hadHistory = await hasHistoricalUsage({ db, userId, sessionId, field: 'exerciseId', value: exerciseId });
    if (hadHistory) {
      continue;
    }
    const event = buildBaseEvent({ sessionId, occurredAt, type: 'first_exercise' });
    event.exerciseId = exerciseId;
    event.value = 1;
    event.previousBest = 0;
    event.delta = 1;
    event.unit = 'count';
    batch.set(eventRef, event, { merge: true });
    createdEvents.push({ id: prId, type: 'first_exercise', exerciseId });
    functions.logger.info('pr_detected', {
      userId,
      sessionId,
      type: 'first_exercise',
      exerciseId,
    });
  }

  for (const [, stat] of metrics.perExercise.entries()) {
    const scope = `exercise:${stat.exerciseId || stat.deviceId}`;
    if (!scope) {
      continue;
    }
    // e1RM PR
    if (stat.bestE1rm && stat.bestE1rm > 0) {
      const prId = deterministicPrId({ userId, sessionId, type: 'e1rm', scope });
      const eventRef = eventsCol.doc(prId);
      const existing = await eventRef.get();
      if (!existing.exists) {
        const previousBest = await getPreviousBest({
          eventsCol,
          type: 'e1rm',
          exerciseId: stat.exerciseId || null,
          deviceId: stat.exerciseId ? null : stat.deviceId || null,
          sessionId,
        });
        if (previousBest == null || stat.bestE1rm > previousBest) {
          const event = buildBaseEvent({ sessionId, occurredAt, type: 'e1rm' });
          if (stat.exerciseId) {
            event.exerciseId = stat.exerciseId;
          }
          if (stat.deviceId) {
            event.deviceId = stat.deviceId;
          }
          event.value = stat.bestE1rm;
          if (previousBest != null) {
            event.previousBest = Math.round(previousBest * 100) / 100;
            event.delta = Math.round((stat.bestE1rm - previousBest) * 100) / 100;
          }
          event.unit = 'kg';
          batch.set(eventRef, event, { merge: true });
          createdEvents.push({ id: prId, type: 'e1rm', exerciseId: stat.exerciseId || null, deviceId: stat.deviceId || null });
          functions.logger.info('pr_detected', {
            userId,
            sessionId,
            type: 'e1rm',
            exerciseId: stat.exerciseId || null,
            deviceId: stat.deviceId || null,
            value: stat.bestE1rm,
            previousBest,
          });
        }
      }
    }
    // Volume PR
    if (stat.volume && stat.volume > 0) {
      const prId = deterministicPrId({ userId, sessionId, type: 'volume', scope });
      const eventRef = eventsCol.doc(prId);
      const existing = await eventRef.get();
      if (!existing.exists) {
        const previousBest = await getPreviousBest({
          eventsCol,
          type: 'volume',
          exerciseId: stat.exerciseId || null,
          deviceId: stat.exerciseId ? null : stat.deviceId || null,
          sessionId,
        });
        if (previousBest == null || stat.volume > previousBest) {
          const event = buildBaseEvent({ sessionId, occurredAt, type: 'volume' });
          if (stat.exerciseId) {
            event.exerciseId = stat.exerciseId;
          }
          if (stat.deviceId) {
            event.deviceId = stat.deviceId;
          }
          const volumeValue = Math.round(stat.volume * 100) / 100;
          event.value = volumeValue;
          if (previousBest != null) {
            event.previousBest = Math.round(previousBest * 100) / 100;
            event.delta = Math.round((volumeValue - previousBest) * 100) / 100;
          }
          event.unit = 'kg';
          batch.set(eventRef, event, { merge: true });
          createdEvents.push({ id: prId, type: 'volume', exerciseId: stat.exerciseId || null, deviceId: stat.deviceId || null });
          functions.logger.info('pr_detected', {
            userId,
            sessionId,
            type: 'volume',
            exerciseId: stat.exerciseId || null,
            deviceId: stat.deviceId || null,
            value: volumeValue,
            previousBest,
          });
        }
      }
    }
  }

  if (createdEvents.length > 0) {
    await batch.commit();
  }

  const sessionEventsSnap = await eventsCol.where('sessionId', '==', sessionId).get();
  const prTypes = new Set();
  sessionEventsSnap.forEach((doc) => {
    const data = doc.data();
    if (typeof data.type === 'string') {
      prTypes.add(data.type);
    }
  });
  await sessionRef.set(
    {
      summary: {
        prCount: sessionEventsSnap.size,
        prTypes: Array.from(prTypes).sort(),
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const xpResult = await xpEngine.awardSessionXp({
    db,
    userId,
    sessionId,
    sessionRef,
    sessionData,
    logs: relevantLogs,
    prEvents: sessionEventsSnap.docs.map((doc) => doc.data() || {}),
  });

  return {
    created: createdEvents.length,
    total: sessionEventsSnap.size,
    xp: xpResult,
  };
}

const onSessionClosed = functions.pubsub
  .topic('session.closed')
  .onPublish(async (message) => {
    const payload = message?.json || {};
    try {
      return await handleSessionClosed(payload);
    } catch (err) {
      functions.logger.error('pr_pipeline_error', err, {
        userId: payload?.userId,
        sessionId: payload?.sessionId,
      });
      throw err;
    }
  });

module.exports = {
  onSessionClosed,
  _test: {
    computeEpleyOneRepMax,
    normalizeLogEntry,
    collectSessionMetrics,
    deterministicPrId,
    handleSessionClosed,
  },
};
