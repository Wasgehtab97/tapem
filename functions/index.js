const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.evaluateChallenges = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const challengesSnap = await db
      .collection('challenges')
      .where('end', '<=', now)
      .get();

    for (const doc of challengesSnap.docs) {
      const challenge = doc.data();
      const participantsSnap = await db
        .collection('users')
        .get();
      for (const user of participantsSnap.docs) {
        const userId = user.id;
        const xpSnap = await db
          .collection('users')
          .doc(userId)
          .collection('muscles')
          .get();
        let totalXp = 0;
        xpSnap.forEach(d => totalXp += d.data().xp || 0);
        if (totalXp >= (challenge.goalXp || 0)) {
          await db
            .collection('users')
            .doc(userId)
            .collection('badges')
            .add({
              challengeId: doc.id,
              awardedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
      }
      await doc.ref.delete();
    }
  });

exports.checkChallengesOnLog = functions.firestore
  .document('gyms/{gymId}/devices/{deviceId}/logs/{logId}')
  .onCreate(async (snap, context) => {
    const { gymId, deviceId } = context.params;
    const data = snap.data();
    const userId = data.userId;
    const sessionId = data.sessionId;
    console.log(
      `📥 new log gym=${gymId} device=${deviceId} user=${userId} session=${sessionId}`
    );
    if (!userId || !sessionId) {
      console.log('🚫 missing userId or sessionId, abort');
      return null;
    }

    const db = admin.firestore();
    const existing = await snap.ref.parent
      .where('sessionId', '==', sessionId)
      .get();
    if (existing.size > 1) {
      console.log(`↩️ additional log for session ${sessionId}`);
    }

    const now = admin.firestore.Timestamp.now();
    const weeklyRef = db
      .collection('gyms')
      .doc(gymId)
      .collection('challenges')
      .doc('weekly')
      .collection('items')
      .where('start', '<=', now)
      .where('end', '>=', now);
    const monthlyRef = db
      .collection('gyms')
      .doc(gymId)
      .collection('challenges')
      .doc('monthly')
      .collection('items')
      .where('start', '<=', now)
      .where('end', '>=', now);

    const [weeklySnap, monthlySnap] = await Promise.all([
      weeklyRef.get(),
      monthlyRef.get(),
    ]);
    const challenges = [...weeklySnap.docs, ...monthlySnap.docs];
    console.log(`🎯 found ${challenges.length} active challenges`);

    for (const doc of challenges) {
      const ch = doc.data();
      const devices = ch.deviceIds || [];
      if (devices.length && !devices.includes(deviceId)) {
        console.log(`➡️ challenge ${doc.id} skipped for device ${deviceId}`);
        continue;
      }
      console.log(`🔍 checking challenge ${doc.id}, minSets=${ch.minSets || 0}`);

      let logCount = 0;
      if (devices.length === 0) {
        const snap = await db
          .collectionGroup('logs')
          .where('userId', '==', userId)
          .where('timestamp', '>=', ch.start)
          .where('timestamp', '<=', ch.end)
          .get();
        logCount = snap.size;
      } else {
        const chunks = [];
        for (let i = 0; i < devices.length; i += 10) {
          chunks.push(devices.slice(i, i + 10 > devices.length ? devices.length : i + 10));
        }

        for (const ids of chunks) {
          const snap = await db
            .collectionGroup('logs')
            .where('userId', '==', userId)
            .where('deviceId', 'in', ids)
            .where('timestamp', '>=', ch.start)
            .where('timestamp', '<=', ch.end)
            .get();
          logCount += snap.size;
        }
      }

      console.log(
        `📊 challenge ${doc.id} requires ${ch.minSets || 0} sets -> ${logCount} logs`
      );
      console.log(
        `📈 challenge ${doc.id} progress ${logCount}/${ch.minSets || 0}`
      );
      if (logCount >= (ch.minSets || 0)) {
        const completedRef = db
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('completedChallenges')
          .doc(doc.id);
        await db.runTransaction(async (tx) => {
          const completedSnap = await tx.get(completedRef);
          if (!completedSnap.exists) {
            tx.set(completedRef, {
              challengeId: doc.id,
              userId,
              title: ch.title || '',
              completedAt: admin.firestore.FieldValue.serverTimestamp(),
              xpReward: ch.xpReward || 0,
            });

            const badgeRef = db
              .collection('users')
              .doc(userId)
              .collection('badges')
              .doc(doc.id);
            const badgeSnap = await tx.get(badgeRef);
            if (!badgeSnap.exists) {
              tx.set(badgeRef, {
                challengeId: doc.id,
                userId,
                awardedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }

            console.log(`📄 completedChallenge doc ${completedRef.path}`);

            const statsRef = db
              .collection('gyms')
              .doc(gymId)
              .collection('users')
              .doc(userId)
              .collection('rank')
              .doc('stats');
            const statsSnap = await tx.get(statsRef);
            const data = statsSnap.data() || {};
            const challengeXp = (data.challengeXP || 0) + (ch.xpReward || 0);
            const dailyXp = (data.dailyXP || 0) + (ch.xpReward || 0);
            if (statsSnap.exists) {
              tx.update(statsRef, {
                challengeXP: challengeXp,
                dailyXP: dailyXp,
              });
            } else {
              tx.set(statsRef, {
                challengeXP: challengeXp,
                dailyXP: dailyXp,
              });
            }
            console.log(
              `🏁 challenge ${doc.id} completed by ${userId}, +${ch.xpReward || 0} XP`
            );
          }
        });
      }
    }
    return null;
  });
exports.sendFriendRequest = functions.https.onCall(async (data, context) => {
  const fromUserId = context.auth && context.auth.uid;
  if (!fromUserId) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const toUserId = data && data.toUserId;
  if (typeof toUserId !== 'string' || toUserId === fromUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid toUserId');
  }
  const db = admin.firestore();
  const requestId = `${fromUserId}_${toUserId}`;
  const requestRef = db
    .collection('users')
    .doc(toUserId)
    .collection('friendRequests')
    .doc(requestId);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(requestRef);
    if (existing.exists && existing.data().status === 'pending') {
      throw new functions.https.HttpsError('already-exists', 'Request already pending');
    }
    tx.set(requestRef, {
      fromUserId,
      toUserId,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    const metaRef = db
      .collection('users')
      .doc(toUserId)
      .collection('friendMeta')
      .doc('meta');
    tx.set(metaRef, {
      pendingCountCache: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  return { requestId };
});

exports.updateFriendRequestStatus = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const { requestId, toUserId, action } = data || {};
  if (typeof requestId !== 'string' || typeof toUserId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid parameters');
  }
  const allowed = ['accept', 'decline', 'cancel'];
  if (!allowed.includes(action)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid action');
  }
  const db = admin.firestore();
  const requestRef = db
    .collection('users')
    .doc(toUserId)
    .collection('friendRequests')
    .doc(requestId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    if (!snap.exists) {
      throw new functions.https.HttpsError('not-found', 'Request not found');
    }
    const req = snap.data();
    if (req.status !== 'pending') {
      return;
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    if (action === 'accept') {
      if (uid !== toUserId) {
        throw new functions.https.HttpsError('permission-denied', 'Only recipient may accept');
      }
      tx.update(requestRef, { status: 'accepted', updatedAt: now });
      const friendRefA = db
        .collection('users')
        .doc(req.fromUserId)
        .collection('friends')
        .doc(req.toUserId);
      const friendRefB = db
        .collection('users')
        .doc(req.toUserId)
        .collection('friends')
        .doc(req.fromUserId);
      tx.set(friendRefA, { friendUid: req.toUserId, since: now }, { merge: true });
      tx.set(friendRefB, { friendUid: req.fromUserId, since: now }, { merge: true });
      const metaRef = db
        .collection('users')
        .doc(toUserId)
        .collection('friendMeta')
        .doc('meta');
      tx.set(metaRef, {
        pendingCountCache: admin.firestore.FieldValue.increment(-1),
        updatedAt: now,
      }, { merge: true });
    } else if (action === 'decline') {
      if (uid !== toUserId) {
        throw new functions.https.HttpsError('permission-denied', 'Only recipient may decline');
      }
      tx.update(requestRef, { status: 'declined', updatedAt: now });
      const metaRef = db
        .collection('users')
        .doc(toUserId)
        .collection('friendMeta')
        .doc('meta');
      tx.set(metaRef, {
        pendingCountCache: admin.firestore.FieldValue.increment(-1),
        updatedAt: now,
      }, { merge: true });
    } else if (action === 'cancel') {
      if (uid !== req.fromUserId) {
        throw new functions.https.HttpsError('permission-denied', 'Only sender may cancel');
      }
      tx.update(requestRef, { status: 'canceled', updatedAt: now });
    }
  });
  return { status: action };
});
