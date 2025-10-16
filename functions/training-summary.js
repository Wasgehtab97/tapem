const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

const SUMMARY_ROOT = 'trainingSummary';
const DAILY_COLLECTION = 'daily';
const AGGREGATE_COLLECTION = 'aggregate';
const AGGREGATE_OVERVIEW_DOC = 'overview';
const TOP_LIMIT = 5;

function sanitizeString(value) {
  if (typeof value !== 'string') {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function coerceTimestamp(raw) {
  if (raw instanceof admin.firestore.Timestamp) {
    return raw;
  }
  if (raw instanceof Date) {
    return admin.firestore.Timestamp.fromDate(raw);
  }
  if (typeof raw === 'number') {
    return admin.firestore.Timestamp.fromMillis(raw);
  }
  return admin.firestore.Timestamp.now();
}

function startOfUtcDay(timestamp) {
  const date = timestamp.toDate();
  const start = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  return admin.firestore.Timestamp.fromDate(start);
}

function toDateKey(timestamp) {
  const date = timestamp.toDate();
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function weekStartOf(timestamp) {
  const date = timestamp.toDate();
  const day = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const weekday = day.getUTCDay();
  const diff = (weekday + 6) % 7; // Monday = 0
  day.setUTCDate(day.getUTCDate() - diff);
  return admin.firestore.Timestamp.fromDate(day);
}

function toWeekKey(timestamp) {
  const weekStart = weekStartOf(timestamp).toDate();
  const year = weekStart.getUTCFullYear();
  const month = String(weekStart.getUTCMonth() + 1).padStart(2, '0');
  const day = String(weekStart.getUTCDate()).padStart(2, '0');
  return `${year}-W${month}${day}`;
}

function cloneCounts(source) {
  if (!source || typeof source !== 'object') {
    return {};
  }
  return JSON.parse(JSON.stringify(source));
}

function incrementObjectEntry(map, key, delta, payload = {}) {
  if (!key) {
    return;
  }
  const next = map[key] || { count: 0, ...payload };
  next.count = (next.count || 0) + delta;
  if (payload && Object.keys(payload).length > 0) {
    Object.assign(next, payload);
  }
  if (next.count <= 0) {
    delete map[key];
    return;
  }
  map[key] = next;
}

function extractMuscleGroups(data) {
  const result = new Set();
  const single = sanitizeString(data.muscleGroup || data.primaryMuscleGroup);
  if (single) {
    result.add(single);
  }
  const plural = data.muscleGroups;
  if (Array.isArray(plural)) {
    plural.forEach((entry) => {
      const value = sanitizeString(entry);
      if (value) {
        result.add(value);
      }
    });
  }
  return Array.from(result);
}

function extractLogPayload(data) {
  const userId = sanitizeString(data.userId || data.userID);
  if (!userId) {
    return null;
  }
  const timestamp = coerceTimestamp(data.timestamp);
  const dateKey = toDateKey(timestamp);
  const dayTimestamp = startOfUtcDay(timestamp);
  const sessionId = sanitizeString(data.sessionId);
  const deviceId = sanitizeString(data.deviceId);
  const exerciseId = sanitizeString(data.exerciseId);
  const exerciseName = sanitizeString(data.exerciseName);
  const muscleGroups = extractMuscleGroups(data);
  return {
    userId,
    timestamp,
    dayTimestamp,
    dateKey,
    sessionId,
    deviceId,
    exerciseId,
    exerciseName,
    muscleGroups,
  };
}

function collectTopEntries(counts) {
  return Object.values(counts || {})
    .filter((entry) => typeof entry.count === 'number' && entry.count > 0)
    .sort((a, b) => b.count - a.count)
    .slice(0, TOP_LIMIT)
    .map((entry) => ({
      id: entry.id || null,
      name: entry.name || entry.id || null,
      count: entry.count,
    }));
}

function computeAggregateFavorites(exerciseCounts) {
  return collectTopEntries(exerciseCounts).map((entry) => ({
    id: entry.id,
    name: entry.name,
    count: entry.count,
  }));
}

function computeAggregateMuscleGroups(muscleCounts) {
  return collectTopEntries(muscleCounts).map((entry) => ({
    id: entry.id || entry.name || null,
    name: entry.name || entry.id || null,
    count: entry.count,
  }));
}

function recomputeBoundaryTimestamp(activeDayKeys, selector) {
  const keys = Object.keys(activeDayKeys || {});
  if (!keys.length) {
    return null;
  }
  const sorted = keys.sort();
  const targetKey = selector === 'min' ? sorted[0] : sorted[sorted.length - 1];
  const [year, month, day] = targetKey.split('-').map((part) => parseInt(part, 10));
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
    return null;
  }
  const date = new Date(Date.UTC(year, month - 1, day));
  return admin.firestore.Timestamp.fromDate(date);
}

function computeAverageTrainingDaysPerWeek(globalData) {
  const weeklyDayCounts = globalData.weeklyDayCounts || {};
  const now = new Date();
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const weekday = today.getUTCDay();
  const diff = weekday === 0 ? 7 : weekday;
  const lastCompletedWeekEnd = new Date(today.getTime());
  lastCompletedWeekEnd.setUTCDate(today.getUTCDate() - diff);
  let completedWeeks = 0;
  let totalDays = 0;
  Object.entries(weeklyDayCounts).forEach(([_, entry]) => {
    if (!entry || typeof entry.count !== 'number' || entry.count <= 0) {
      return;
    }
    const startString = entry.startDate;
    if (typeof startString !== 'string') {
      return;
    }
    const parts = startString.split('-').map((part) => parseInt(part, 10));
    if (parts.length !== 3 || parts.some((value) => !Number.isFinite(value))) {
      return;
    }
    const start = new Date(Date.UTC(parts[0], parts[1] - 1, parts[2]));
    if (start.getTime() > lastCompletedWeekEnd.getTime()) {
      return;
    }
    completedWeeks += 1;
    totalDays += entry.count;
  });
  if (completedWeeks <= 0 || totalDays <= 0) {
    return 0;
  }
  return totalDays / completedWeeks;
}

function requireAdminContext(context) {
  const isAdmin = Boolean(context.auth?.token?.admin);
  if (!isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin privileges required');
  }
}

function parseBackfillOptions(raw) {
  const options = raw && typeof raw === 'object' ? raw : {};
  const dryRun = Boolean(options.dryRun);
  const batchSize = Number.isFinite(options.batchSize)
    ? Math.min(Math.max(Math.floor(options.batchSize), 1), 2000)
    : 500;
  const resumeToken = typeof options.resumeToken === 'string' ? options.resumeToken : null;
  return { dryRun, batchSize, resumeToken };
}

function encodeResumeToken(cursor) {
  if (
    !cursor ||
    typeof cursor.lastTimestampMillis !== 'number' ||
    !Number.isFinite(cursor.lastTimestampMillis) ||
    typeof cursor.lastDocumentPath !== 'string' ||
    cursor.lastDocumentPath.length === 0
  ) {
    return null;
  }
  const payload = {
    lastTimestampMillis: cursor.lastTimestampMillis,
    lastDocumentPath: cursor.lastDocumentPath,
  };
  return Buffer.from(JSON.stringify(payload)).toString('base64');
}

function decodeResumeToken(token) {
  if (!token) {
    return null;
  }
  try {
    const json = Buffer.from(token, 'base64').toString('utf8');
    const data = JSON.parse(json);
    if (
      data &&
      Number.isFinite(data.lastTimestampMillis) &&
      typeof data.lastDocumentPath === 'string' &&
      data.lastDocumentPath.length > 0
    ) {
      return {
        lastTimestampMillis: Number(data.lastTimestampMillis),
        lastDocumentPath: data.lastDocumentPath,
      };
    }
  } catch (error) {
    console.warn('Failed to decode resume token', error);
  }
  return null;
}

const BACKFILL_ADMIN_COLLECTION = 'admin';
const BACKFILL_ADMIN_DOC = 'backfillState';
const BACKFILL_STATE_DOC = 'state';

function getBackfillStateRef(job) {
  return admin
    .firestore()
    .collection(BACKFILL_ADMIN_COLLECTION)
    .doc(BACKFILL_ADMIN_DOC)
    .collection(job)
    .doc(BACKFILL_STATE_DOC);
}

function createBulkWriter(db) {
  const writer = db.bulkWriter();
  writer.onWriteError((error) => {
    console.error('BulkWriter error', error);
    if (error.failedAttempts < 5) {
      console.warn(
        `Retrying write for ${error.documentRef?.path || 'unknown'} (attempt ${error.failedAttempts + 1})`
      );
      return true;
    }
    return false;
  });
  return writer;
}

async function readStoredResumeToken(job, explicitToken) {
  if (explicitToken) {
    return decodeResumeToken(explicitToken);
  }
  const snapshot = await getBackfillStateRef(job).get();
  if (!snapshot.exists) {
    return null;
  }
  const data = snapshot.data() || {};
  if (typeof data.resumeToken === 'string') {
    const decoded = decodeResumeToken(data.resumeToken);
    if (decoded) {
      return decoded;
    }
  }
  if (Number.isFinite(data.lastTimestampMillis) && typeof data.lastDocumentPath === 'string') {
    return {
      lastTimestampMillis: data.lastTimestampMillis,
      lastDocumentPath: data.lastDocumentPath,
    };
  }
  return null;
}

async function writeStoredResumeToken(job, cursor, metrics) {
  const ref = getBackfillStateRef(job);
  if (!cursor) {
    await ref.delete().catch((error) => {
      if (error.code !== 5 && error.code !== 'not-found') {
        throw error;
      }
    });
    return 0;
  }
  const payload = {
    lastTimestampMillis: cursor.lastTimestampMillis,
    lastDocumentPath: cursor.lastDocumentPath,
    resumeToken: encodeResumeToken(cursor),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (metrics && typeof metrics === 'object') {
    payload.metrics = metrics;
  }
  await ref.set(payload, { merge: true });
  return 1;
}

async function iterateLogs(processLog, options = {}) {
  const db = admin.firestore();
  const { batchSize = 500, resumeCursor = null } = options;
  const baseQuery = db
    .collectionGroup('logs')
    .orderBy('timestamp', 'asc')
    .orderBy(admin.firestore.FieldPath.documentId(), 'asc')
    .limit(batchSize);

  let nextCursor = resumeCursor ? { ...resumeCursor } : null;
  let lastCursor = resumeCursor ? { ...resumeCursor } : null;
  let processed = 0;
  let readCount = 0;
  let hasMore = true;

  while (hasMore) {
    let query = baseQuery;
    if (nextCursor) {
      const startTimestamp = admin.firestore.Timestamp.fromMillis(nextCursor.lastTimestampMillis);
      query = query.startAfter(startTimestamp, nextCursor.lastDocumentPath);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      hasMore = false;
      break;
    }

    readCount += snapshot.size;

    for (const doc of snapshot.docs) {
      const timestamp = doc.get('timestamp');
      if (!(timestamp instanceof admin.firestore.Timestamp)) {
        console.warn(`Skipping log without timestamp: ${doc.ref.path}`);
        continue;
      }
      await processLog(doc, timestamp);
      processed += 1;
      lastCursor = {
        lastTimestampMillis: timestamp.toMillis(),
        lastDocumentPath: doc.ref.path,
      };
      if (processed % 10000 === 0) {
        console.log(`Processed ${processed} logs so far...`);
      }
    }

    if (snapshot.size < batchSize) {
      hasMore = false;
    } else {
      nextCursor = lastCursor;
    }
  }

  return { processed, readCount, lastCursor, hasMore };
}

function ensureDailyAccumulator(map, userId, payload) {
  const key = `${userId}::${payload.dateKey}`;
  if (!map.has(key)) {
    map.set(key, {
      userId,
      dateKey: payload.dateKey,
      date: payload.dayTimestamp,
      logCount: 0,
      sessionCounts: {},
      exerciseCounts: {},
      muscleGroupCounts: {},
      deviceCounts: {},
      favoriteExercises: [],
      muscleGroups: [],
      totalSessions: 0,
    });
  }
  return map.get(key);
}

function ensureAggregateAccumulator(map, userId) {
  if (!map.has(userId)) {
    map.set(userId, {
      userId,
      totalLogCount: 0,
      trainingDayCount: 0,
      activeDayKeys: {},
      weeklyDayCounts: {},
      exerciseCounts: {},
      muscleGroupCounts: {},
      deviceCounts: {},
      favoriteExercises: [],
      muscleGroups: [],
      totalSessions: 0,
      firstWorkoutDate: null,
      lastWorkoutDate: null,
      userCreatedAt: null,
      averageTrainingDaysPerWeek: 0,
      sessionIds: new Set(),
    });
  }
  return map.get(userId);
}

function computeDailyDerivedFields(daily) {
  daily.favoriteExercises = computeAggregateFavorites(daily.exerciseCounts);
  daily.muscleGroups = computeAggregateMuscleGroups(daily.muscleGroupCounts);
  daily.totalSessions = Object.values(daily.sessionCounts || {})
    .filter((entry) => entry && typeof entry.count === 'number' && entry.count > 0)
    .length;
  return daily;
}

function computeAggregateDerivedFields(aggregate) {
  aggregate.favoriteExercises = computeAggregateFavorites(aggregate.exerciseCounts);
  aggregate.muscleGroups = computeAggregateMuscleGroups(aggregate.muscleGroupCounts);
  aggregate.totalSessions = aggregate.sessionIds ? aggregate.sessionIds.size : 0;
  delete aggregate.sessionIds;
  aggregate.averageTrainingDaysPerWeek = computeAverageTrainingDaysPerWeek(aggregate);
  return aggregate;
}

function extractGymAndDevice(doc) {
  const logsCollection = doc.ref.parent;
  if (!logsCollection) {
    return { gymId: null, deviceId: null };
  }
  const deviceDoc = logsCollection.parent;
  const devicesCollection = deviceDoc?.parent;
  const gymDoc = devicesCollection?.parent;
  return {
    gymId: gymDoc?.id || null,
    deviceId: deviceDoc?.id || null,
  };
}

function ensureDeviceAccumulator(map, gymId, deviceId) {
  const key = `${gymId}::${deviceId}`;
  if (!map.has(key)) {
    map.set(key, {
      gymId,
      deviceId,
      sessionTimestamps: new Map(),
      lastActive: null,
    });
  }
  return map.get(key);
}

function computeDeviceSummaryPayload(record) {
  const sessions = Array.from(record.sessionTimestamps.entries());
  sessions.sort((a, b) => b[1] - a[1]);
  const recentDates = sessions.slice(0, 10).map(([_, millis]) => new Date(millis));
  const now = Date.now();
  const msInDay = 24 * 60 * 60 * 1000;
  const thresholds = {
    last7Days: now - 7 * msInDay,
    last30Days: now - 30 * msInDay,
    last90Days: now - 90 * msInDay,
    last365Days: now - 365 * msInDay,
  };
  const counts = {
    last7Days: 0,
    last30Days: 0,
    last90Days: 0,
    last365Days: 0,
    all: sessions.length,
  };
  sessions.forEach(([, millis]) => {
    if (millis >= thresholds.last7Days) {
      counts.last7Days += 1;
    }
    if (millis >= thresholds.last30Days) {
      counts.last30Days += 1;
    }
    if (millis >= thresholds.last90Days) {
      counts.last90Days += 1;
    }
    if (millis >= thresholds.last365Days) {
      counts.last365Days += 1;
    }
  });

  return {
    sessionCount: sessions.length,
    rollingSessions: counts,
    recentDates,
    lastActive: record.lastActive ? new Date(record.lastActive) : null,
  };
}

async function backfillTrainingSummariesHandler(data, context) {
  requireAdminContext(context);
  const { dryRun, batchSize, resumeToken } = parseBackfillOptions(data);
  const resumeCursor = await readStoredResumeToken('training', resumeToken);

  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();
  const dailyMap = new Map();
  const aggregateMap = new Map();

  const iteration = await iterateLogs(
    async (doc) => {
      const payload = extractLogPayload(doc.data() || {});
      if (!payload) {
        return;
      }
      const { gymId } = extractGymAndDevice(doc);
      const daily = ensureDailyAccumulator(dailyMap, payload.userId, payload);
      daily.logCount += 1;
      if (payload.sessionId) {
        incrementObjectEntry(daily.sessionCounts, payload.sessionId, 1, {
          id: payload.sessionId,
          gymId: gymId || null,
          deviceId: payload.deviceId || null,
        });
      }
      if (payload.exerciseId || payload.exerciseName) {
        const key = payload.exerciseId || payload.exerciseName;
        incrementObjectEntry(daily.exerciseCounts, key, 1, {
          id: payload.exerciseId || null,
          name: payload.exerciseName || payload.exerciseId || null,
        });
      }
      if (payload.deviceId) {
        incrementObjectEntry(daily.deviceCounts, payload.deviceId, 1, {
          id: payload.deviceId,
          name: payload.deviceId,
        });
      }
      payload.muscleGroups.forEach((group) => {
        incrementObjectEntry(daily.muscleGroupCounts, group, 1, {
          id: group,
          name: group,
        });
      });

      const aggregate = ensureAggregateAccumulator(aggregateMap, payload.userId);
      aggregate.totalLogCount += 1;
      if (payload.sessionId) {
        aggregate.sessionIds.add(payload.sessionId);
      }
      let addedDay = false;
      if (!aggregate.activeDayKeys[payload.dateKey]) {
        aggregate.activeDayKeys[payload.dateKey] = true;
        aggregate.trainingDayCount += 1;
        addedDay = true;
      }
      incrementObjectEntry(aggregate.exerciseCounts, payload.exerciseId || payload.exerciseName, 1, {
        id: payload.exerciseId || null,
        name: payload.exerciseName || payload.exerciseId || null,
      });
      payload.muscleGroups.forEach((group) => {
        incrementObjectEntry(aggregate.muscleGroupCounts, group, 1, {
          id: group,
          name: group,
        });
      });
      if (payload.deviceId) {
        incrementObjectEntry(aggregate.deviceCounts, payload.deviceId, 1, {
          id: payload.deviceId,
          name: payload.deviceId,
        });
      }

      const weekKey = toWeekKey(payload.dayTimestamp);
      const weekStart = weekStartOf(payload.dayTimestamp).toDate();
      const weekStartKey = `${weekStart.getUTCFullYear()}-${String(weekStart.getUTCMonth() + 1).padStart(2, '0')}-${String(weekStart.getUTCDate()).padStart(2, '0')}`;
      if (addedDay) {
        const weekEntry = aggregate.weeklyDayCounts[weekKey] || { count: 0, startDate: weekStartKey };
        weekEntry.count = Math.max(0, Number(weekEntry.count || 0) + 1);
        weekEntry.startDate = weekStartKey;
        aggregate.weeklyDayCounts[weekKey] = weekEntry;

        const millis = payload.dayTimestamp.toMillis();
        if (!aggregate.firstWorkoutDate || aggregate.firstWorkoutDate.toMillis() > millis) {
          aggregate.firstWorkoutDate = payload.dayTimestamp;
        }
        if (!aggregate.lastWorkoutDate || aggregate.lastWorkoutDate.toMillis() < millis) {
          aggregate.lastWorkoutDate = payload.dayTimestamp;
        }
      } else if (aggregate.lastWorkoutDate && aggregate.lastWorkoutDate.toMillis() < payload.dayTimestamp.toMillis()) {
        aggregate.lastWorkoutDate = payload.dayTimestamp;
      }
    },
    { batchSize, resumeCursor }
  );

  const resumeInfo = iteration.hasMore ? iteration.lastCursor : null;
  const exposedResumeToken = iteration.lastCursor ? encodeResumeToken(iteration.lastCursor) : null;
  const result = {
    dryRun,
    logsProcessed: iteration.processed,
    estimatedReads: iteration.readCount,
    estimatedWrites: 0,
    hasMore: iteration.hasMore,
    resumeToken: exposedResumeToken,
    dailyCount: dailyMap.size,
    aggregateCount: aggregateMap.size,
  };

  if (dryRun) {
    return result;
  }

  const db = admin.firestore();
  const writer = createBulkWriter(db);

  dailyMap.forEach((daily) => {
    computeDailyDerivedFields(daily);
    const { userId, ...rest } = daily;
    const dailyRef = db
      .collection(SUMMARY_ROOT)
      .doc(userId)
      .collection(DAILY_COLLECTION)
      .doc(daily.dateKey);
    writer.set(
      dailyRef,
      {
        ...rest,
        updatedAt: serverTimestamp,
      },
      { merge: false }
    );
  });

  aggregateMap.forEach((aggregate, userId) => {
    computeAggregateDerivedFields(aggregate);
    const aggregateRef = db
      .collection(SUMMARY_ROOT)
      .doc(userId)
      .collection(AGGREGATE_COLLECTION)
      .doc(AGGREGATE_OVERVIEW_DOC);
    writer.set(
      aggregateRef,
      {
        ...aggregate,
        updatedAt: serverTimestamp,
      },
      { merge: false }
    );
  });

  await writer.close();

  result.estimatedWrites = dailyMap.size + aggregateMap.size;
  const stateWrites = await writeStoredResumeToken('training', resumeInfo, {
    logsProcessed: iteration.processed,
    estimatedReads: iteration.readCount,
  });
  result.estimatedWrites += stateWrites;

  return result;
}

async function backfillDeviceUsageSummariesHandler(data, context) {
  requireAdminContext(context);
  const { dryRun, batchSize, resumeToken } = parseBackfillOptions(data);
  const resumeCursor = await readStoredResumeToken('device', resumeToken);

  const deviceMap = new Map();

  const iteration = await iterateLogs(
    async (doc) => {
      const payload = extractLogPayload(doc.data() || {});
      if (!payload) {
        return;
      }
      const { gymId, deviceId } = extractGymAndDevice(doc);
      if (!gymId || !deviceId || !payload.sessionId) {
        return;
      }
      const accumulator = ensureDeviceAccumulator(deviceMap, gymId, deviceId);
      const millis = payload.timestamp.toMillis();
      const existing = accumulator.sessionTimestamps.get(payload.sessionId) || 0;
      if (millis > existing) {
        accumulator.sessionTimestamps.set(payload.sessionId, millis);
      }
      if (!accumulator.lastActive || accumulator.lastActive < millis) {
        accumulator.lastActive = millis;
      }
    },
    { batchSize, resumeCursor }
  );

  const resumeInfo = iteration.hasMore ? iteration.lastCursor : null;
  const exposedResumeToken = iteration.lastCursor ? encodeResumeToken(iteration.lastCursor) : null;
  const result = {
    dryRun,
    logsProcessed: iteration.processed,
    estimatedReads: iteration.readCount,
    estimatedWrites: 0,
    hasMore: iteration.hasMore,
    resumeToken: exposedResumeToken,
    deviceCount: deviceMap.size,
  };

  if (dryRun) {
    return result;
  }

  const db = admin.firestore();
  const writer = createBulkWriter(db);
  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

  deviceMap.forEach((record) => {
    const summary = computeDeviceSummaryPayload(record);
    const ref = db
      .collection('deviceUsageSummary')
      .doc(record.gymId)
      .collection('devices')
      .doc(record.deviceId);
    writer.set(
      ref,
      {
        sessionCount: summary.sessionCount,
        rollingSessions: summary.rollingSessions,
        recentDates: summary.recentDates.map((date) => admin.firestore.Timestamp.fromDate(date)),
        lastActive: summary.lastActive ? admin.firestore.Timestamp.fromDate(summary.lastActive) : null,
        updatedAt: serverTimestamp,
      },
      { merge: true }
    );
  });

  await writer.close();

  result.estimatedWrites = deviceMap.size;
  const stateWrites = await writeStoredResumeToken('device', resumeInfo, {
    logsProcessed: iteration.processed,
    estimatedReads: iteration.readCount,
  });
  result.estimatedWrites += stateWrites;

  return result;
}

async function updateTrainingSummary(change, context) {
  const afterData = change.after.exists ? change.after.data() : null;
  const beforeData = change.before.exists ? change.before.data() : null;

  if (!afterData && !beforeData) {
    return null;
  }

  const payloads = [];
  const contextGymId = sanitizeString(context.params?.gymId);
  if (beforeData) {
    const extracted = extractLogPayload(beforeData);
    if (extracted) {
      payloads.push({ ...extracted, delta: -1, gymId: contextGymId });
    }
  }
  if (afterData) {
    const extracted = extractLogPayload(afterData);
    if (extracted) {
      payloads.push({ ...extracted, delta: 1, gymId: contextGymId });
    }
  }

  if (!payloads.length) {
    return null;
  }

  const db = admin.firestore();
  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

  await Promise.all(
    payloads.map(async (payload) => {
      const { userId, dateKey, dayTimestamp, delta, sessionId, deviceId, exerciseId, exerciseName, muscleGroups, gymId } = payload;
      const dailyRef = db
        .collection(SUMMARY_ROOT)
        .doc(userId)
        .collection(DAILY_COLLECTION)
        .doc(dateKey);
      const aggregateRef = db
        .collection(SUMMARY_ROOT)
        .doc(userId)
        .collection(AGGREGATE_COLLECTION)
        .doc(AGGREGATE_OVERVIEW_DOC);

      await db.runTransaction(async (tx) => {
        const dailySnap = await tx.get(dailyRef);
        const aggregateSnap = await tx.get(aggregateRef);

        const dailyData = dailySnap.exists ? dailySnap.data() : {};
        const aggregateData = aggregateSnap.exists ? aggregateSnap.data() : {};

        const prevLogCount = Number(dailyData.logCount || 0);
        const prevActive = prevLogCount > 0;

        const nextLogCount = Math.max(0, prevLogCount + delta);
        const nextDaily = {
          dateKey,
          date: dayTimestamp,
          logCount: nextLogCount,
          sessionCounts: cloneCounts(dailyData.sessionCounts),
          exerciseCounts: cloneCounts(dailyData.exerciseCounts),
          muscleGroupCounts: cloneCounts(dailyData.muscleGroupCounts),
          deviceCounts: cloneCounts(dailyData.deviceCounts),
          favoriteExercises: [],
          muscleGroups: [],
          totalSessions: 0,
          updatedAt: serverTimestamp,
        };

        if (sessionId) {
          incrementObjectEntry(nextDaily.sessionCounts, sessionId, delta, {
            id: sessionId,
            gymId: gymId || null,
            deviceId: deviceId || null,
          });
        }
        if (exerciseId || exerciseName) {
          const key = exerciseId || exerciseName;
          incrementObjectEntry(nextDaily.exerciseCounts, key, delta, {
            id: exerciseId || null,
            name: exerciseName || exerciseId || null,
          });
        }
        if (deviceId) {
          incrementObjectEntry(nextDaily.deviceCounts, deviceId, delta, {
            id: deviceId,
            name: deviceId,
          });
        }
        muscleGroups.forEach((group) => {
          incrementObjectEntry(nextDaily.muscleGroupCounts, group, delta, {
            id: group,
            name: group,
          });
        });

        nextDaily.favoriteExercises = computeAggregateFavorites(nextDaily.exerciseCounts);
        nextDaily.muscleGroups = computeAggregateMuscleGroups(nextDaily.muscleGroupCounts);
        nextDaily.totalSessions = Object.values(nextDaily.sessionCounts || {}).filter(
          (entry) => entry && typeof entry.count === 'number' && entry.count > 0
        ).length;

        const aggregate = {
          userId,
          updatedAt: serverTimestamp,
          totalLogCount: Math.max(0, Number(aggregateData.totalLogCount || 0) + delta),
          trainingDayCount: Number(aggregateData.trainingDayCount || 0),
          activeDayKeys: cloneCounts(aggregateData.activeDayKeys),
          weeklyDayCounts: cloneCounts(aggregateData.weeklyDayCounts),
          exerciseCounts: cloneCounts(aggregateData.exerciseCounts),
          muscleGroupCounts: cloneCounts(aggregateData.muscleGroupCounts),
          deviceCounts: cloneCounts(aggregateData.deviceCounts),
          favoriteExercises: [],
          muscleGroups: [],
          totalSessions: Number(aggregateData.totalSessions || 0),
          firstWorkoutDate: aggregateData.firstWorkoutDate || null,
          lastWorkoutDate: aggregateData.lastWorkoutDate || null,
          userCreatedAt: aggregateData.userCreatedAt || null,
          averageTrainingDaysPerWeek: 0,
        };

        if (sessionId) {
          // totalSessions is derived below to avoid counting every set multiple times.
        }
        if (exerciseId || exerciseName) {
          const key = exerciseId || exerciseName;
          incrementObjectEntry(aggregate.exerciseCounts, key, delta, {
            id: exerciseId || null,
            name: exerciseName || exerciseId || null,
          });
        }
        muscleGroups.forEach((group) => {
          incrementObjectEntry(aggregate.muscleGroupCounts, group, delta, {
            id: group,
            name: group,
          });
        });
        if (deviceId) {
          incrementObjectEntry(aggregate.deviceCounts, deviceId, delta, {
            id: deviceId,
            name: deviceId,
          });
        }

        const aggregateActive = aggregate.activeDayKeys;
        const weekKey = toWeekKey(dayTimestamp);
        const weekStart = weekStartOf(dayTimestamp).toDate();
        const weekStartKey = `${weekStart.getUTCFullYear()}-${String(weekStart.getUTCMonth() + 1).padStart(2, '0')}-${String(weekStart.getUTCDate()).padStart(2, '0')}`;

        if (!prevActive && nextLogCount > 0) {
          aggregate.trainingDayCount += 1;
          aggregateActive[dateKey] = true;
          const weekEntry = aggregate.weeklyDayCounts[weekKey] || { count: 0, startDate: weekStartKey };
          weekEntry.count = Math.max(0, Number(weekEntry.count || 0) + 1);
          weekEntry.startDate = weekStartKey;
          aggregate.weeklyDayCounts[weekKey] = weekEntry;
          aggregate.firstWorkoutDate = aggregate.firstWorkoutDate
            ? (aggregate.firstWorkoutDate.toMillis && aggregate.firstWorkoutDate.toMillis() <= dayTimestamp.toMillis()
              ? aggregate.firstWorkoutDate
              : dayTimestamp)
            : dayTimestamp;
          aggregate.lastWorkoutDate = aggregate.lastWorkoutDate
            ? (aggregate.lastWorkoutDate.toMillis && aggregate.lastWorkoutDate.toMillis() >= dayTimestamp.toMillis()
              ? aggregate.lastWorkoutDate
              : dayTimestamp)
            : dayTimestamp;
        } else if (prevActive && nextLogCount === 0) {
          aggregate.trainingDayCount = Math.max(0, aggregate.trainingDayCount - 1);
          delete aggregateActive[dateKey];
          const weekEntry = aggregate.weeklyDayCounts[weekKey];
          if (weekEntry) {
            weekEntry.count = Math.max(0, Number(weekEntry.count || 0) - 1);
            if (weekEntry.count <= 0) {
              delete aggregate.weeklyDayCounts[weekKey];
            } else {
              aggregate.weeklyDayCounts[weekKey] = weekEntry;
            }
          }
          aggregate.firstWorkoutDate = recomputeBoundaryTimestamp(aggregateActive, 'min');
          aggregate.lastWorkoutDate = recomputeBoundaryTimestamp(aggregateActive, 'max');
        } else if (nextLogCount > 0) {
          aggregate.lastWorkoutDate = aggregate.lastWorkoutDate
            ? (aggregate.lastWorkoutDate.toMillis && aggregate.lastWorkoutDate.toMillis() >= dayTimestamp.toMillis()
              ? aggregate.lastWorkoutDate
              : dayTimestamp)
            : dayTimestamp;
        }

        aggregate.favoriteExercises = computeAggregateFavorites(aggregate.exerciseCounts);
        aggregate.muscleGroups = computeAggregateMuscleGroups(aggregate.muscleGroupCounts);
        aggregate.totalSessions = aggregate.trainingDayCount;
        aggregate.averageTrainingDaysPerWeek = computeAverageTrainingDaysPerWeek(aggregate);

        if (nextLogCount <= 0) {
          tx.delete(dailyRef);
        } else {
          tx.set(dailyRef, nextDaily, { merge: false });
        }
        tx.set(aggregateRef, aggregate, { merge: false });
      });
    })
  );

  return null;
}

const mirrorTrainingSummary = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onWrite(updateTrainingSummary);

const backfillTrainingSummaries = functions.runWith({
  timeoutSeconds: 540,
  memory: '1GB',
}).https.onCall(backfillTrainingSummariesHandler);

const backfillDeviceUsageSummaries = functions.runWith({
  timeoutSeconds: 540,
  memory: '1GB',
}).https.onCall(backfillDeviceUsageSummariesHandler);

module.exports = {
  mirrorTrainingSummary,
  backfillTrainingSummaries,
  backfillDeviceUsageSummaries,
};
