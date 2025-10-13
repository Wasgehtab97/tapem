const functions = require('firebase-functions');
const admin = require('firebase-admin');

const EXERCISE_MUSCLE_MAP = require('./data/exercise_muscles.json');

function toNumber(value) {
  if (value == null) {
    return null;
  }
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

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function computeSetXp({ weight = 0, reps = 0, rir = null, isBodyweight = false }) {
  if (!Number.isFinite(reps) || reps <= 0) {
    return 0;
  }
  const safeWeight = Number.isFinite(weight) && weight > 0 && !isBodyweight ? weight : 0;
  let intensity = reps + safeWeight / 10;
  if (safeWeight === 0) {
    intensity += 2;
  }
  let multiplier = 1;
  if (Number.isFinite(rir)) {
    const normalized = clamp(10 - clamp(rir, 0, 5), 0, 10) / 5;
    multiplier = clamp(0.5 + normalized, 0.5, 1.5);
  }
  const raw = intensity * 2 * multiplier;
  return Math.max(1, Math.round(raw));
}

function extractSetsFromLog(data) {
  const sets = [];
  if (!data || typeof data !== 'object') {
    return sets;
  }
  const reps = toNumber(data.reps ?? data.repCount ?? data.repetitions);
  const weight = toNumber(data.weight ?? data.weightKg ?? data.loadKg ?? data.massKg);
  const rir = toNumber(data.rir ?? data.targetRir ?? data.estimatedRir);
  const isBodyweight = data.isBodyweight === true || data.loadType === 'bodyweight';
  if (reps && reps > 0) {
    sets.push({ weight: weight ?? 0, reps, rir, isBodyweight });
  }
  const drops = Array.isArray(data.drops)
    ? data.drops
    : Array.isArray(data.dropSets)
      ? data.dropSets
      : [];
  for (const drop of drops) {
    if (!drop || typeof drop !== 'object') {
      continue;
    }
    const dropReps = toNumber(drop.reps ?? drop.repCount);
    const dropWeight = toNumber(drop.weight ?? drop.weightKg ?? drop.loadKg);
    if (dropReps && dropReps > 0) {
      sets.push({ weight: dropWeight ?? 0, reps: dropReps, rir, isBodyweight });
    }
  }
  return sets;
}

function resolveMuscles({ exerciseId, logData }) {
  const muscles = new Set();
  if (exerciseId && Array.isArray(EXERCISE_MUSCLE_MAP[exerciseId])) {
    for (const id of EXERCISE_MUSCLE_MAP[exerciseId]) {
      if (typeof id === 'string' && id.trim() !== '') {
        muscles.add(id.trim());
      }
    }
  }
  const fromPrimary = Array.isArray(logData?.primaryMuscleGroupIds) ? logData.primaryMuscleGroupIds : [];
  const fromSecondary = Array.isArray(logData?.secondaryMuscleGroupIds) ? logData.secondaryMuscleGroupIds : [];
  const fromGeneric = Array.isArray(logData?.muscleGroupIds) ? logData.muscleGroupIds : [];
  for (const source of [fromPrimary, fromSecondary, fromGeneric]) {
    for (const id of source) {
      if (typeof id === 'string' && id.trim() !== '') {
        muscles.add(id.trim());
      }
    }
  }
  return Array.from(muscles);
}

const BONUS_VALUES = {
  e1rm: 10,
  volume: 5,
  first_device: 3,
  first_exercise: 3,
};

function computeSessionXp({ logs, prEvents = [] }) {
  let baseXp = 0;
  let bonusXp = 0;
  const perDevice = new Map();
  const perMuscle = new Map();
  const bonusBreakdown = new Map();
  const logBreakdown = [];

  for (const log of logs) {
    if (!log || typeof log.data !== 'function') {
      continue;
    }
    const payload = log.data() || {};
    const deviceId = typeof payload.deviceId === 'string' && payload.deviceId.trim() !== ''
      ? payload.deviceId.trim()
      : null;
    const exerciseId = typeof payload.exerciseId === 'string' && payload.exerciseId.trim() !== ''
      ? payload.exerciseId.trim()
      : null;
    const muscles = resolveMuscles({ exerciseId, logData: payload });
    const sets = extractSetsFromLog(payload);
    let logXp = 0;
    for (const set of sets) {
      const amount = computeSetXp(set);
      if (amount <= 0) {
        continue;
      }
      baseXp += amount;
      logXp += amount;
      if (deviceId) {
        perDevice.set(deviceId, (perDevice.get(deviceId) || 0) + amount);
      }
      if (muscles.length > 0) {
        const perMuscleShare = amount / muscles.length;
        for (const muscleId of muscles) {
          perMuscle.set(muscleId, (perMuscle.get(muscleId) || 0) + perMuscleShare);
        }
      }
    }
    if (logXp > 0) {
      logBreakdown.push({ deviceId, exerciseId, xp: logXp, muscleCount: muscles.length });
    }
  }

  for (const event of prEvents) {
    if (!event || typeof event !== 'object') {
      continue;
    }
    const type = event.type;
    const bonus = BONUS_VALUES[type] || 0;
    if (!bonus) {
      continue;
    }
    bonusXp += bonus;
    bonusBreakdown.set(type, (bonusBreakdown.get(type) || 0) + bonus);
    const deviceId = typeof event.deviceId === 'string' && event.deviceId.trim() !== '' ? event.deviceId.trim() : null;
    const exerciseId = typeof event.exerciseId === 'string' && event.exerciseId.trim() !== '' ? event.exerciseId.trim() : null;
    if (deviceId) {
      perDevice.set(deviceId, (perDevice.get(deviceId) || 0) + bonus);
    }
    if (exerciseId) {
      const muscles = resolveMuscles({ exerciseId, logData: {} });
      if (muscles.length > 0) {
        const perMuscleShare = bonus / muscles.length;
        for (const muscleId of muscles) {
          perMuscle.set(muscleId, (perMuscle.get(muscleId) || 0) + perMuscleShare);
        }
      }
    }
  }

  const roundedMuscles = new Map();
  for (const [muscleId, value] of perMuscle.entries()) {
    roundedMuscles.set(muscleId, Math.round(value * 100) / 100);
  }

  return {
    totalXp: baseXp + bonusXp,
    baseXp,
    bonusXp,
    perDevice,
    perMuscle: roundedMuscles,
    bonuses: bonusBreakdown,
    logBreakdown,
  };
}

function formatDateKey(date) {
  const d = date instanceof Date ? date : new Date();
  const iso = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate())).toISOString();
  return iso.slice(0, 10).replace(/-/g, '');
}

function getDayRef({ db, userId, dayKey }) {
  return db.collection('users').doc(userId).collection('xp').doc('daily').collection('days').doc(dayKey);
}

async function awardSessionXp({ db, userId, sessionId, sessionRef, sessionData, logs, prEvents }) {
  const occurredAt = sessionData?.endAt instanceof admin.firestore.Timestamp
    ? sessionData.endAt.toDate()
    : sessionData?.updatedAt instanceof admin.firestore.Timestamp
      ? sessionData.updatedAt.toDate()
      : new Date();
  const dayKey = formatDateKey(occurredAt);
  const xp = computeSessionXp({ logs, prEvents });
  const dayRef = getDayRef({ db, userId, dayKey });
  let awarded = false;
  let updatedTotal = xp.totalXp;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(dayRef);
    const data = snap.exists ? snap.data() || {} : {};
    const sessions = Array.isArray(data.sessions) ? data.sessions.slice() : [];
    if (sessions.includes(sessionId)) {
      awarded = false;
      updatedTotal = data.total ?? 0;
      return;
    }
    sessions.push(sessionId);
    sessions.sort();
    const byDevice = { ...(data.byDevice || {}) };
    for (const [deviceId, value] of xp.perDevice.entries()) {
      if (!deviceId) {
        continue;
      }
      const prev = Number.isFinite(byDevice[deviceId]) ? byDevice[deviceId] : 0;
      byDevice[deviceId] = Math.round((prev + value) * 100) / 100;
    }
    const byMuscle = { ...(data.byMuscle || {}) };
    for (const [muscleId, value] of xp.perMuscle.entries()) {
      if (!muscleId) {
        continue;
      }
      const prev = Number.isFinite(byMuscle[muscleId]) ? byMuscle[muscleId] : 0;
      byMuscle[muscleId] = Math.round((prev + value) * 100) / 100;
    }
    const total = Number.isFinite(data.total) ? data.total : 0;
    updatedTotal = Math.round((total + xp.totalXp) * 100) / 100;
    tx.set(
      dayRef,
      {
        total: updatedTotal,
        byDevice,
        byMuscle,
        sessions,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    awarded = true;
  });

  await sessionRef.set(
    {
      summary: {
        xpTotal: xp.totalXp,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const topMuscles = Array.from(xp.perMuscle.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([muscleId, value]) => ({ muscleId, xp: Math.round(value * 100) / 100 }));

  functions.logger.info('analytics_event', {
    event: 'xp_awarded',
    userId,
    sessionId,
    day: dayKey,
    xp: {
      total: xp.totalXp,
      base: xp.baseXp,
      bonus: xp.bonusXp,
    },
    deviceCount: xp.perDevice.size,
    topMuscles,
    bonuses: Array.from(xp.bonuses.entries()).map(([type, value]) => ({ type, xp: value })),
    awarded,
  });

  return {
    awarded,
    dayKey,
    totalXp: xp.totalXp,
    baseXp: xp.baseXp,
    bonusXp: xp.bonusXp,
  };
}

module.exports = {
  awardSessionXp,
  computeSessionXp,
  computeSetXp,
  extractSetsFromLog,
  _test: {
    toNumber,
    clamp,
    EXERCISE_MUSCLE_MAP,
    resolveMuscles,
    formatDateKey,
    getDayRef,
  },
};
