const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Mapping of supported disciplines to their stable IDs and field prefixes.
// The IDs must stay in sync with PowerliftingDiscipline.id in the Flutter app.
const DISCIPLINES = [
  { id: 'bench_press', prefix: 'bench' },
  { id: 'squat', prefix: 'squat' },
  { id: 'deadlift', prefix: 'deadlift' },
];

function computeE1rm(weight, reps) {
  if (!Number.isFinite(weight) || !Number.isFinite(reps) || weight <= 0 || reps <= 0) {
    return 0;
  }
  return weight * (1 + reps / 30);
}

function toNumber(value) {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string' && value.trim().length) {
    return Number(value);
  }
  return Number(value || 0);
}

function isTimestamp(value) {
  return value instanceof admin.firestore.Timestamp;
}

function isLaterTimestamp(candidate, current) {
  if (!isTimestamp(candidate)) {
    return false;
  }
  if (!isTimestamp(current)) {
    return true;
  }
  return candidate.toMillis() > current.toMillis();
}

async function fetchBestForAssignment({ db, gymId, uid, deviceId, exerciseId }) {
  const logsSnap = await db
    .collection('gyms')
    .doc(gymId)
    .collection('devices')
    .doc(deviceId)
    .collection('logs')
    .where('userId', '==', uid)
    .where('exerciseId', '==', exerciseId)
    .get();

  let heaviestKg = 0;
  let heaviestReps = 0;
  let heaviestAt = null;
  let e1rmKg = 0;
  let e1rmAt = null;

  for (const doc of logsSnap.docs) {
    const data = doc.data() || {};
    const weight = toNumber(data.weight);
    const reps = Math.trunc(toNumber(data.reps));
    if (!Number.isFinite(weight) || !Number.isFinite(reps) || weight <= 0 || reps <= 0) {
      continue;
    }

    const ts = isTimestamp(data.timestamp) ? data.timestamp : null;
    const e1rm = computeE1rm(weight, reps);

    if (
      weight > heaviestKg ||
      (weight === heaviestKg && isLaterTimestamp(ts, heaviestAt))
    ) {
      heaviestKg = weight;
      heaviestReps = reps;
      heaviestAt = ts;
    }

    if (
      e1rm > e1rmKg ||
      (e1rm === e1rmKg && isLaterTimestamp(ts, e1rmAt))
    ) {
      e1rmKg = e1rm;
      e1rmAt = ts;
    }
  }

  return {
    heaviestKg,
    heaviestReps,
    heaviestAt,
    e1rmKg,
    e1rmAt,
  };
}

async function recomputePowerliftingForUserGym({ db, uid, gymId }) {
  if (!uid || !gymId) {
    return;
  }

  const assignmentsSnap = await db
    .collection('users')
    .doc(uid)
    .collection('powerlifting_sources')
    .where('gymId', '==', gymId)
    .get();

  const assignmentsByDiscipline = new Map();
  for (const disc of DISCIPLINES) {
    assignmentsByDiscipline.set(disc.id, []);
  }

  for (const doc of assignmentsSnap.docs) {
    const data = doc.data() || {};
    const disciplineId = data.discipline;
    const deviceId = data.deviceId;
    const exerciseId = data.exerciseId;
    if (
      !assignmentsByDiscipline.has(disciplineId) ||
      typeof deviceId !== 'string' ||
      !deviceId ||
      typeof exerciseId !== 'string' ||
      !exerciseId
    ) {
      continue;
    }
    assignmentsByDiscipline.get(disciplineId).push({
      deviceId,
      exerciseId,
    });
  }

  const statsRef = db
    .collection('gyms')
    .doc(gymId)
    .collection('users')
    .doc(uid)
    .collection('rank')
    .doc('powerlifting');

  const update = {};
  let totalE1rmKg = 0;
  let hasAnyMetric = false;

  for (const disc of DISCIPLINES) {
    const prefix = disc.prefix;
    const heaviestKey = `${prefix}HeaviestKg`;
    const heaviestRepsKey = `${prefix}HeaviestReps`;
    const heaviestAtKey = `${prefix}HeaviestAt`;
    const e1rmKey = `${prefix}E1rmKg`;
    const e1rmAtKey = `${prefix}E1rmAt`;

    const assignments = assignmentsByDiscipline.get(disc.id) || [];
    let bestHeaviestKg = 0;
    let bestHeaviestReps = 0;
    let bestHeaviestAt = null;
    let bestE1rmKg = 0;
    let bestE1rmAt = null;

    for (const assignment of assignments) {
      const best = await fetchBestForAssignment({
        db,
        gymId,
        uid,
        deviceId: assignment.deviceId,
        exerciseId: assignment.exerciseId,
      });

      if (
        best.heaviestKg > bestHeaviestKg ||
        (best.heaviestKg === bestHeaviestKg &&
          isLaterTimestamp(best.heaviestAt, bestHeaviestAt))
      ) {
        bestHeaviestKg = best.heaviestKg;
        bestHeaviestReps = best.heaviestReps;
        bestHeaviestAt = best.heaviestAt;
      }

      if (
        best.e1rmKg > bestE1rmKg ||
        (best.e1rmKg === bestE1rmKg &&
          isLaterTimestamp(best.e1rmAt, bestE1rmAt))
      ) {
        bestE1rmKg = best.e1rmKg;
        bestE1rmAt = best.e1rmAt;
      }
    }

    if (bestHeaviestKg > 0) {
      update[heaviestKey] = bestHeaviestKg;
      update[heaviestRepsKey] = bestHeaviestReps;
      update[heaviestAtKey] = bestHeaviestAt || admin.firestore.FieldValue.serverTimestamp();
      hasAnyMetric = true;
    } else {
      update[heaviestKey] = admin.firestore.FieldValue.delete();
      update[heaviestRepsKey] = admin.firestore.FieldValue.delete();
      update[heaviestAtKey] = admin.firestore.FieldValue.delete();
    }

    if (bestE1rmKg > 0) {
      update[e1rmKey] = bestE1rmKg;
      update[e1rmAtKey] = bestE1rmAt || admin.firestore.FieldValue.serverTimestamp();
      totalE1rmKg += bestE1rmKg;
      hasAnyMetric = true;
    } else {
      update[e1rmKey] = admin.firestore.FieldValue.delete();
      update[e1rmAtKey] = admin.firestore.FieldValue.delete();
    }
  }

  if (!hasAnyMetric) {
    const existing = await statsRef.get();
    if (existing.exists) {
      await statsRef.delete();
    }
    return;
  }

  update.totalE1rmKg = totalE1rmKg;
  update.updatedAt = admin.firestore.FieldValue.serverTimestamp();
  await statsRef.set(update, { merge: true });
}

async function handleLogMutation(snap, context) {
  const { gymId } = context.params;
  const data = snap.data() || {};
  const uid = typeof data.userId === 'string' ? data.userId : '';
  if (!gymId || !uid) {
    return null;
  }

  const db = admin.firestore();
  await recomputePowerliftingForUserGym({ db, uid, gymId });
  return null;
}

// Keep exported name for backwards compatibility.
exports.updatePowerliftingRankOnLog = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onCreate((snap, context) => handleLogMutation(snap, context));

exports.updatePowerliftingRankOnLogDelete = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onDelete((snap, context) => handleLogMutation(snap, context));

exports.updatePowerliftingRankOnAssignmentWrite = functions.firestore
  .document('users/{uid}/powerlifting_sources/{assignmentId}')
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    if (!uid) {
      return null;
    }

    const before = change.before.exists ? change.before.data() || {} : {};
    const after = change.after.exists ? change.after.data() || {} : {};

    const gymIds = new Set();
    if (typeof before.gymId === 'string' && before.gymId) {
      gymIds.add(before.gymId);
    }
    if (typeof after.gymId === 'string' && after.gymId) {
      gymIds.add(after.gymId);
    }

    if (!gymIds.size) {
      return null;
    }

    const db = admin.firestore();
    for (const gymId of gymIds) {
      await recomputePowerliftingForUserGym({ db, uid, gymId });
    }
    return null;
  });
