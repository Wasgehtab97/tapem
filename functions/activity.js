const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

function sanitizeString(value) {
  if (typeof value !== 'string') {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function sanitizeNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return undefined;
}

function buildDeviceLogActivityEvent(data, context, options = {}) {
  const { gymId, deviceId, logId } = context.params;
  if (!gymId || !deviceId || !logId) {
    return null;
  }

  const nowTimestamp = options.now instanceof admin.firestore.Timestamp ? options.now : admin.firestore.Timestamp.now();
  const serverTimestamp = options.serverTimestamp || admin.firestore.FieldValue.serverTimestamp();

  const rawTimestamp = data.timestamp;
  const timestamp = rawTimestamp instanceof admin.firestore.Timestamp ? rawTimestamp : nowTimestamp;
  const userId = sanitizeString(data.userId ?? data.userID);
  const sessionId = sanitizeString(data.sessionId);
  const exerciseName = sanitizeString(data.exerciseName);
  const exerciseId = sanitizeString(data.exerciseId);
  const setType = sanitizeString(data.setType);

  const summaryParts = ['Trainingseintrag gespeichert'];
  if (exerciseName) {
    summaryParts.push(`(${exerciseName})`);
  } else if (exerciseId) {
    summaryParts.push(`(${exerciseId})`);
  }
  const summary = summaryParts.join(' ');

  const payload = {};
  if (exerciseId) {
    payload.exerciseId = exerciseId;
  }
  if (exerciseName) {
    payload.exerciseName = exerciseName;
  }
  if (setType) {
    payload.setType = setType;
  }
  const reps = sanitizeNumber(data.reps ?? data.repeatCount);
  if (reps !== undefined) {
    payload.reps = reps;
  }
  const weight = sanitizeNumber(data.weight ?? data.weightKg);
  if (weight !== undefined) {
    payload.weight = weight;
  }
  const duration = sanitizeNumber(data.durationSeconds ?? data.duration ?? data.timeUnderTension);
  if (duration !== undefined) {
    payload.duration = duration;
  }
  const distance = sanitizeNumber(data.distance ?? data.distanceMeters);
  if (distance !== undefined) {
    payload.distance = distance;
  }
  const calories = sanitizeNumber(data.calories);
  if (calories !== undefined) {
    payload.calories = calories;
  }

  const actor = userId ? { type: 'user', id: userId } : { type: 'system' };
  const targets = [];
  if (sessionId) {
    targets.push({ type: 'session', id: sessionId });
  }
  if (exerciseId) {
    targets.push({ type: 'exercise', id: exerciseId });
  }

  const event = {
    gymId,
    timestamp,
    eventType: 'training.set_logged',
    severity: 'info',
    source: 'device',
    summary,
    userId: userId || undefined,
    deviceId,
    sessionId: sessionId || undefined,
    actor,
    targets: targets.length > 0 ? targets : undefined,
    data: Object.keys(payload).length > 0 ? payload : undefined,
    updatedAt: serverTimestamp,
    idempotencyKey: `${gymId}:${deviceId}:${logId}`,
  };

  return event;
}

const mirrorDeviceLogToActivity = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const event = buildDeviceLogActivityEvent(data, context);
    if (!event) {
      console.warn('activity-mirror: invalid payload, skipping', context.params);
      return null;
    }

    const db = admin.firestore();
    const activityId = `device:${context.params.logId}`;
    const activityRef = db.collection('gyms').doc(context.params.gymId).collection('activity').doc(activityId);

    await activityRef.set(event, { merge: false });
    console.info('activity-mirror: mirrored log to activity', {
      gymId: context.params.gymId,
      deviceId: context.params.deviceId,
      logId: context.params.logId,
      activityId,
    });
    return null;
  });

module.exports = {
  buildDeviceLogActivityEvent,
  mirrorDeviceLogToActivity,
};
