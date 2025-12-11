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

/**
 * Firestore trigger that keeps per-user powerlifting stats up to date.
 *
 * Whenever a new log is written for a device, we look up whether that
 * (gym, device, exercise) triple is linked to one of the powerlifting
 * disciplines for the user by checking the powerlifting_sources mapping.
 *
 * If so, we update the user's per-discipline heaviest set and E1RM and
 * recompute a combined totalE1rmKg used for leaderboard ranking:
 *
 *   gyms/{gymId}/users/{uid}/rank/powerlifting
 */
exports.updatePowerliftingRankOnLog = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onCreate(async (snap, context) => {
    const { gymId, deviceId } = context.params;
    const data = snap.data() || {};

    const uid = data.userId;
    const exerciseId = data.exerciseId || deviceId;

    if (!uid || !gymId || !deviceId || !exerciseId) {
      return null;
    }

    const rawWeight = data.weight;
    const rawReps = data.reps;
    const weight = typeof rawWeight === 'number' ? rawWeight : Number(rawWeight || 0);
    const reps = typeof rawReps === 'number' ? rawReps : Number(rawReps || 0);

    if (!Number.isFinite(weight) || !Number.isFinite(reps) || weight <= 0 || reps <= 0) {
      return null;
    }

    const db = admin.firestore();
    const assignmentsCol = db.collection('users').doc(uid).collection('powerlifting_sources');

    const disciplinesForLog = [];

    // Check for each discipline whether a matching assignment exists for this
    // (gym, device, exercise) triple. The assignment document ID is constructed
    // as `${disciplineId}|${gymId}|${deviceId}|${exerciseId}` on the client.
    await Promise.all(
      DISCIPLINES.map(async (disc) => {
        const assignmentId = `${disc.id}|${gymId}|${deviceId}|${exerciseId}`;
        const assignmentSnap = await assignmentsCol.doc(assignmentId).get();
        if (assignmentSnap.exists) {
          disciplinesForLog.push(disc);
        }
      }),
    );

    if (!disciplinesForLog.length) {
      // This log does not contribute to any powerlifting discipline.
      return null;
    }

    const e1rm = computeE1rm(weight, reps);
    if (e1rm <= 0) {
      return null;
    }

    const statsRef = db
      .collection('gyms')
      .doc(gymId)
      .collection('users')
      .doc(uid)
      .collection('rank')
      .doc('powerlifting');

    const logTimestamp =
      data.timestamp instanceof admin.firestore.Timestamp
        ? data.timestamp
        : admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (tx) => {
      const statsSnap = await tx.get(statsRef);
      const existing = statsSnap.exists ? statsSnap.data() || {} : {};
      const update = {};

      for (const disc of disciplinesForLog) {
        const prefix = disc.prefix;
        const heaviestKey = `${prefix}HeaviestKg`;
        const heaviestRepsKey = `${prefix}HeaviestReps`;
        const heaviestAtKey = `${prefix}HeaviestAt`;
        const e1rmKey = `${prefix}E1rmKg`;
        const e1rmAtKey = `${prefix}E1rmAt`;

        const prevHeaviest =
          typeof existing[heaviestKey] === 'number' ? existing[heaviestKey] : 0;
        const prevE1rm =
          typeof existing[e1rmKey] === 'number' ? existing[e1rmKey] : 0;

        if (weight > prevHeaviest) {
          update[heaviestKey] = weight;
          update[heaviestRepsKey] = reps;
          update[heaviestAtKey] = logTimestamp;
        }

        if (e1rm > prevE1rm) {
          update[e1rmKey] = e1rm;
          update[e1rmAtKey] = logTimestamp;
        }
      }

      const merged = { ...existing, ...update };
      let totalE1rm = 0;
      for (const disc of DISCIPLINES) {
        const v = merged[`${disc.prefix}E1rmKg`];
        if (typeof v === 'number' && v > 0) {
          totalE1rm += v;
        }
      }

      update.totalE1rmKg = totalE1rm;
      update.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      tx.set(statsRef, update, { merge: true });
    });

    return null;
  });

