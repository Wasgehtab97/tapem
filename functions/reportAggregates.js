const functions = require('firebase-functions');
const admin = require('firebase-admin');

function resolveDate(value) {
  if (!value) {
    return null;
  }
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value;
  }
  if (typeof value.toDate === 'function') {
    const date = value.toDate();
    if (date instanceof Date && !Number.isNaN(date.getTime())) {
      return date;
    }
  }
  if (typeof value === 'number' || typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return null;
}

function dayKeyUtc(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}${m}${d}`;
}

function asInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  return 0;
}

function normalizeMap(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }
  const result = {};
  Object.entries(value).forEach(([key, raw]) => {
    result[key] = asInt(raw);
  });
  return result;
}

function incrementMap(map, key, delta) {
  const next = { ...map };
  const current = asInt(next[key]);
  const updated = current + delta;
  if (updated <= 0) {
    delete next[key];
  } else {
    next[key] = updated;
  }
  return next;
}

function markerId(deviceId, logId) {
  return `${encodeURIComponent(deviceId)}__${encodeURIComponent(logId)}`;
}

function sessionCounterId(deviceId, sessionId) {
  return `${encodeURIComponent(deviceId)}__${encodeURIComponent(sessionId)}`;
}

function isEmptyMap(map) {
  return Object.keys(map).length === 0;
}

async function handleLogCreate({
  db,
  gymId,
  deviceId,
  logId,
  timestamp,
  sessionId,
}) {
  const logDate = resolveDate(timestamp) || new Date();
  const dayKey = dayKeyUtc(logDate);
  const hourKey = String(logDate.getUTCHours());
  const dayRef = db.collection('gyms').doc(gymId).collection('reportDaily').doc(dayKey);
  const markerRef = dayRef.collection('_logMarkers').doc(markerId(deviceId, logId));
  const hasSession = typeof sessionId === 'string' && sessionId.trim().length > 0;
  const normalizedSessionId = hasSession ? sessionId.trim() : null;
  const sessionRef = normalizedSessionId
    ? dayRef.collection('_sessionCounters').doc(sessionCounterId(deviceId, normalizedSessionId))
    : null;

  await db.runTransaction(async (tx) => {
    const existingMarker = await tx.get(markerRef);
    if (existingMarker.exists) {
      return;
    }

    const daySnap = await tx.get(dayRef);
    const dayData = daySnap.exists ? daySnap.data() : {};
    const deviceLogCounts = normalizeMap(dayData?.deviceLogCounts);
    const deviceSessionCounts = normalizeMap(dayData?.deviceSessionCounts);
    const hourBuckets = normalizeMap(dayData?.hourBuckets);

    let totalLogs = asInt(dayData?.totalLogs) + 1;
    let totalSessions = asInt(dayData?.totalSessions);
    const nextDeviceLogCounts = incrementMap(deviceLogCounts, deviceId, 1);
    let nextDeviceSessionCounts = { ...deviceSessionCounts };
    const nextHourBuckets = incrementMap(hourBuckets, hourKey, 1);

    if (sessionRef) {
      const sessionSnap = await tx.get(sessionRef);
      const currentCount = sessionSnap.exists ? asInt(sessionSnap.data()?.count) : 0;
      if (currentCount <= 0) {
        totalSessions += 1;
        nextDeviceSessionCounts = incrementMap(nextDeviceSessionCounts, deviceId, 1);
      }
      tx.set(
        sessionRef,
        {
          count: currentCount + 1,
          sessionId: normalizedSessionId,
          deviceId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    tx.set(markerRef, {
      deviceId,
      logId,
      sessionId: normalizedSessionId,
      hour: asInt(hourKey),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(
      dayRef,
      {
        dayKey,
        totalLogs,
        totalSessions,
        deviceLogCounts: nextDeviceLogCounts,
        deviceSessionCounts: nextDeviceSessionCounts,
        hourBuckets: nextHourBuckets,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

async function handleLogDelete({
  db,
  gymId,
  deviceId,
  logId,
  timestamp,
  sessionId,
}) {
  const logDate = resolveDate(timestamp);
  if (!logDate) {
    return;
  }
  const dayKey = dayKeyUtc(logDate);
  const hourKey = String(logDate.getUTCHours());
  const dayRef = db.collection('gyms').doc(gymId).collection('reportDaily').doc(dayKey);
  const markerRef = dayRef.collection('_logMarkers').doc(markerId(deviceId, logId));
  const hasSession = typeof sessionId === 'string' && sessionId.trim().length > 0;
  const normalizedSessionId = hasSession ? sessionId.trim() : null;
  const sessionRef = normalizedSessionId
    ? dayRef.collection('_sessionCounters').doc(sessionCounterId(deviceId, normalizedSessionId))
    : null;

  await db.runTransaction(async (tx) => {
    const markerSnap = await tx.get(markerRef);
    if (!markerSnap.exists) {
      return;
    }

    const daySnap = await tx.get(dayRef);
    const dayData = daySnap.exists ? daySnap.data() : {};
    const deviceLogCounts = normalizeMap(dayData?.deviceLogCounts);
    const deviceSessionCounts = normalizeMap(dayData?.deviceSessionCounts);
    const hourBuckets = normalizeMap(dayData?.hourBuckets);

    let totalLogs = Math.max(0, asInt(dayData?.totalLogs) - 1);
    let totalSessions = Math.max(0, asInt(dayData?.totalSessions));
    const nextDeviceLogCounts = incrementMap(deviceLogCounts, deviceId, -1);
    let nextDeviceSessionCounts = { ...deviceSessionCounts };
    const nextHourBuckets = incrementMap(hourBuckets, hourKey, -1);

    if (sessionRef) {
      const sessionSnap = await tx.get(sessionRef);
      if (sessionSnap.exists) {
        const currentCount = asInt(sessionSnap.data()?.count);
        if (currentCount <= 1) {
          tx.delete(sessionRef);
          totalSessions = Math.max(0, totalSessions - 1);
          nextDeviceSessionCounts = incrementMap(nextDeviceSessionCounts, deviceId, -1);
        } else {
          tx.set(
            sessionRef,
            {
              count: currentCount - 1,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      }
    }

    tx.delete(markerRef);

    if (
      totalLogs <= 0 &&
      totalSessions <= 0 &&
      isEmptyMap(nextDeviceLogCounts) &&
      isEmptyMap(nextDeviceSessionCounts) &&
      isEmptyMap(nextHourBuckets)
    ) {
      tx.delete(dayRef);
      return;
    }

    tx.set(
      dayRef,
      {
        dayKey,
        totalLogs,
        totalSessions,
        deviceLogCounts: nextDeviceLogCounts,
        deviceSessionCounts: nextDeviceSessionCounts,
        hourBuckets: nextHourBuckets,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

exports.onDeviceLogCreatedUpdateReportDaily = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onCreate(async (snap, context) => {
    const { gymId, deviceId, logId } = context.params;
    const data = snap.data() || {};
    await handleLogCreate({
      db: admin.firestore(),
      gymId,
      deviceId,
      logId,
      timestamp: data.timestamp,
      sessionId: data.sessionId,
    });
    return null;
  });

exports.onDeviceLogDeletedUpdateReportDaily = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onDelete(async (snap, context) => {
    const { gymId, deviceId, logId } = context.params;
    const data = snap.data() || {};
    await handleLogDelete({
      db: admin.firestore(),
      gymId,
      deviceId,
      logId,
      timestamp: data.timestamp,
      sessionId: data.sessionId,
    });
    return null;
  });

exports._private = {
  resolveDate,
  dayKeyUtc,
  incrementMap,
  normalizeMap,
  handleLogCreate,
  handleLogDelete,
};
