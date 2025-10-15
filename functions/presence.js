const functions = require('firebase-functions');
const admin = require('firebase-admin');

const PRESENCE_ROOT = 'dailyPresence';

function sanitizeUserId(raw) {
  if (typeof raw !== 'string') {
    return null;
  }
  const trimmed = raw.trim();
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

function toDateKey(timestamp) {
  const date = timestamp.toDate();
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function startOfUtcDay(timestamp) {
  const date = timestamp.toDate();
  const start = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  return admin.firestore.Timestamp.fromDate(start);
}

function endOfUtcDay(timestamp) {
  const start = startOfUtcDay(timestamp).toDate();
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return admin.firestore.Timestamp.fromDate(end);
}

async function markPresenceTrue(db, userId, timestamp, logId) {
  const dateKey = toDateKey(timestamp);
  const ref = db
    .collection(PRESENCE_ROOT)
    .doc(dateKey)
    .collection('users')
    .doc(userId);
  await ref.set(
    {
      workedOut: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogId: logId,
    },
    { merge: true }
  );
  return ref.path;
}

async function maybeMarkPresenceFalse(db, userId, timestamp) {
  const dateKey = toDateKey(timestamp);
  const start = startOfUtcDay(timestamp);
  const end = endOfUtcDay(timestamp);
  const remaining = await db
    .collectionGroup('logs')
    .where('userId', '==', userId)
    .where('timestamp', '>=', start)
    .where('timestamp', '<', end)
    .limit(1)
    .get();
  if (remaining.size > 0) {
    return null;
  }
  const ref = db
    .collection(PRESENCE_ROOT)
    .doc(dateKey)
    .collection('users')
    .doc(userId);
  await ref.set(
    {
      workedOut: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return ref.path;
}

const mirrorLogPresence = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onWrite(async (change, context) => {
    const db = admin.firestore();
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    if (after) {
      const userId = sanitizeUserId(after.userId || after.userID);
      if (!userId) {
        return null;
      }
      const timestamp = coerceTimestamp(after.timestamp);
      const path = await markPresenceTrue(db, userId, timestamp, context.params.logId);
      functions.logger.debug('presence: marked workedOut', { path, userId });
      return null;
    }

    if (before) {
      const userId = sanitizeUserId(before.userId || before.userID);
      if (!userId) {
        return null;
      }
      const timestamp = coerceTimestamp(before.timestamp);
      const path = await maybeMarkPresenceFalse(db, userId, timestamp);
      if (path) {
        functions.logger.debug('presence: cleared workedOut', { path, userId });
      }
    }

    return null;
  });

module.exports = {
  mirrorLogPresence,
};
