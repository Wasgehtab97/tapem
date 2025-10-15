const functions = require('firebase-functions');
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

module.exports = {
  mirrorTrainingSummary,
};
