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

exports.mirrorPublicProfile = functions.firestore
  .document('users/{uid}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) {
      console.log(`mirrorPublicProfile: ${context.params.uid} deleted → skip`);
      return null;
    }
    const { username, usernameLower, primaryGymCode, avatarUrl, createdAt } = after;
    const profile = {
      username: username || '',
      usernameLower: (usernameLower || (username ? username.toLowerCase() : '')) || '',
      primaryGymCode: primaryGymCode || null,
      avatarUrl: avatarUrl || null,
      createdAt:
        createdAt || admin.firestore.FieldValue.serverTimestamp(),
    };
    await admin
      .firestore()
      .collection('publicProfiles')
      .doc(context.params.uid)
      .set(profile, { merge: true });
    console.log(`mirrorPublicProfile: mirrored ${context.params.uid}`);
    return null;
  });

exports.backfillPublicProfiles = functions.https.onCall(async (_, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }
  const db = admin.firestore();
  const snap = await db.collection('users').get();
  let processed = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (!data.username) continue;
    const profile = {
      username: data.username,
      usernameLower:
        data.usernameLower || (data.username ? data.username.toLowerCase() : ''),
      primaryGymCode: data.primaryGymCode || null,
      avatarUrl: data.avatarUrl || null,
      createdAt:
        data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
    };
    await db
      .collection('publicProfiles')
      .doc(doc.id)
      .set(profile, { merge: true });
    processed += 1;
  }
  console.log(`backfillPublicProfiles: processed ${processed}`);
  return { processed };
});

// -------------------- FRIENDS --------------------
async function sendPushToUser(uid, message) {
  const tokensSnap = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('pushTokens')
    .get();
  if (tokensSnap.empty) {
    console.log(`FRIENDS: no push tokens for ${uid}`);
    return;
  }
  const tokens = tokensSnap.docs.map((d) => d.id);
  try {
    await admin.messaging().sendEachForMulticast({
      tokens,
      ...message,
    });
  } catch (e) {
    console.log(`FRIENDS: push error`, e);
  }
}

exports.sendFriendRequest = functions.https.onCall(async (data, context) => {
  const fromUserId = context.auth && context.auth.uid;
  if (!fromUserId) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const toUserId = data && data.toUserId;
  const message = data && data.message;
  if (typeof toUserId !== 'string' || toUserId === fromUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid toUserId');
  }
  if (message && typeof message !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid message');
  }
  if (message && message.length > 300) {
    throw new functions.https.HttpsError('invalid-argument', 'Message too long');
  }

  const db = admin.firestore();
  const requestId = `${fromUserId}_${toUserId}`;
  const requestRef = db
    .collection('users')
    .doc(toUserId)
    .collection('friendRequests')
    .doc(requestId);
  const rateRef = db.collection('rateLimits').doc(fromUserId);
  const metaRef = db
    .collection('users')
    .doc(toUserId)
    .collection('friendMeta')
    .doc('meta');
  const friendRefA = db
    .collection('users')
    .doc(fromUserId)
    .collection('friends')
    .doc(toUserId);
  const friendRefB = db
    .collection('users')
    .doc(toUserId)
    .collection('friends')
    .doc(fromUserId);
  const toUserRef = db.collection('users').doc(toUserId);
  const fromUserRef = db.collection('users').doc(fromUserId);

  await db.runTransaction(async (tx) => {
    const now = admin.firestore.Timestamp.now();
    const [rateSnap, requestSnap, friendASnap, friendBSnap, toUserSnap, fromUserSnap, metaSnap] = await Promise.all([
      tx.get(rateRef),
      tx.get(requestRef),
      tx.get(friendRefA),
      tx.get(friendRefB),
      tx.get(toUserRef),
      tx.get(fromUserRef),
      tx.get(metaRef),
    ]);

    if (requestSnap.exists && ['pending', 'accepted'].includes(requestSnap.data().status)) {
      throw new functions.https.HttpsError('already-exists', 'Request already exists');
    }
    if (friendASnap.exists || friendBSnap.exists) {
      throw new functions.https.HttpsError('already-exists', 'Users already friends');
    }

    const toData = toUserSnap.data() || {};
    const fromData = fromUserSnap.data() || {};
    const allow = toData.allowFriendRequests || 'everyone';
    if (allow === 'noone') {
      throw new functions.https.HttpsError('permission-denied', 'User does not allow requests');
    }
    if (allow === 'same_gym') {
      const toGyms = toData.gymCodes || [];
      const fromGyms = fromData.gymCodes || [];
      const shared = toGyms.filter((g) => fromGyms.includes(g));
      if (!shared.length) {
        throw new functions.https.HttpsError('permission-denied', 'Users do not share a gym');
      }
    }

    let count = 0;
    let resetAt = now;
    if (rateSnap.exists) {
      const data = rateSnap.data();
      count = data.count || 0;
      resetAt = data.resetAt || now;
      if (data.resetAt && data.resetAt.toMillis() + 3600000 < now.toMillis()) {
        count = 0;
        resetAt = now;
      }
    }
    if (count >= 10) {
      throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded');
    }
    tx.set(rateRef, { count: count + 1, resetAt }, { merge: true });

    tx.set(
      requestRef,
      {
        fromUserId,
        toUserId,
        status: 'pending',
        message: message || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const pending = (metaSnap.data() && metaSnap.data().pendingCountCache) || 0;
    tx.set(
      metaRef,
      {
        pendingCountCache: pending + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  // Push notification to recipient
  try {
    const profileSnap = await admin
      .firestore()
      .collection('publicProfiles')
      .doc(fromUserId)
      .get();
    const username = (profileSnap.exists && profileSnap.data().username) || 'Jemand';
    await sendPushToUser(toUserId, {
      notification: {
        title: 'Neue Freundschaftsanfrage',
        body: `${username}`,
      },
      data: { action: 'open_requests' },
    });
  } catch (e) {
    console.log('FRIENDS: push failed', e);
  }

  console.log(`FRIENDS: request ${requestId} from ${fromUserId} to ${toUserId}`);
  return { requestId, status: 'pending' };
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
  const fromUid = requestId.split('_')[0];
  const db = admin.firestore();
  const requestRef = db
    .collection('users')
    .doc(toUserId)
    .collection('friendRequests')
    .doc(requestId);
  const metaRef = db
    .collection('users')
    .doc(toUserId)
    .collection('friendMeta')
    .doc('meta');
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    if (!snap.exists) {
      throw new functions.https.HttpsError('not-found', 'Request not found');
    }
    const req = snap.data();
    if (req.status !== 'pending') {
      return { status: req.status };
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
      const [fromSnap, toSnap, metaSnap, friendASnap, friendBSnap] = await Promise.all([
        tx.get(db.collection('users').doc(req.fromUserId)),
        tx.get(db.collection('users').doc(req.toUserId)),
        tx.get(metaRef),
        tx.get(friendRefA),
        tx.get(friendRefB),
      ]);
      if (!friendASnap.exists) {
        tx.set(
          friendRefA,
          {
            friendUid: req.toUserId,
            since: now,
            gymCodesAtAcceptance: [
              ...(fromSnap.data().gymCodes || []),
              ...(toSnap.data().gymCodes || []),
            ],
            createdAt: now,
            updatedAt: now,
          },
          { merge: true }
        );
      }
      if (!friendBSnap.exists) {
        tx.set(
          friendRefB,
          {
            friendUid: req.fromUserId,
            since: now,
            gymCodesAtAcceptance: [
              ...(fromSnap.data().gymCodes || []),
              ...(toSnap.data().gymCodes || []),
            ],
            createdAt: now,
            updatedAt: now,
          },
          { merge: true }
        );
      }
      const pending = (metaSnap.data() && metaSnap.data().pendingCountCache) || 0;
      tx.set(metaRef, { pendingCountCache: Math.max(0, pending - 1), updatedAt: now }, { merge: true });
    } else if (action === 'decline') {
      if (uid !== toUserId) {
        throw new functions.https.HttpsError('permission-denied', 'Only recipient may decline');
      }
      const metaSnap = await tx.get(metaRef);
      const pending = (metaSnap.data() && metaSnap.data().pendingCountCache) || 0;
      tx.update(requestRef, { status: 'declined', updatedAt: now });
      tx.set(metaRef, { pendingCountCache: Math.max(0, pending - 1), updatedAt: now }, { merge: true });
    } else if (action === 'cancel') {
      if (uid !== req.fromUserId) {
        throw new functions.https.HttpsError('permission-denied', 'Only sender may cancel');
      }
      tx.update(requestRef, { status: 'canceled', updatedAt: now });
      if (req.status === 'pending') {
        const metaSnap = await tx.get(metaRef);
        const pending = (metaSnap.data() && metaSnap.data().pendingCountCache) || 0;
        tx.set(metaRef, { pendingCountCache: Math.max(0, pending - 1), updatedAt: now }, { merge: true });
      }
    }
  });

  if (action === 'accept') {
    try {
      const profileSnap = await admin
        .firestore()
        .collection('publicProfiles')
        .doc(toUserId)
        .get();
      const username = (profileSnap.exists && profileSnap.data().username) || 'Jemand';
      await sendPushToUser(fromUid, {
        notification: {
          title: 'Anfrage akzeptiert',
          body: `${username}`,
        },
        data: { action: 'open_friend', uid: toUserId },
      });
    } catch (e) {
      console.log('FRIENDS: push failed', e);
    }
  }

  console.log(`FRIENDS: request ${requestId} ${action} by ${uid}`);
  return { status: action };
});

exports.removeFriend = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const otherUserId = data && data.otherUserId;
  if (typeof otherUserId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid otherUserId');
  }
  const db = admin.firestore();
  const aRef = db.collection('users').doc(uid).collection('friends').doc(otherUserId);
  const bRef = db.collection('users').doc(otherUserId).collection('friends').doc(uid);
  await db.runTransaction(async (tx) => {
    const [aSnap, bSnap] = await Promise.all([tx.get(aRef), tx.get(bRef)]);
    if (!aSnap.exists || !bSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Not friends');
    }
    tx.delete(aRef);
    tx.delete(bRef);
  });
  console.log(`FRIENDS: ${uid} removed ${otherUserId}`);
  return { status: 'removed' };
});

exports.registerPushToken = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const token = data && data.token;
  const platform = data && data.platform;
  if (typeof token !== 'string' || !token) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid token');
  }
  const db = admin.firestore();
  const ref = db.collection('users').doc(uid).collection('pushTokens').doc(token);
  await ref.set(
    {
      platform: platform || 'unknown',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { status: 'ok' };
});

exports.setFriendRequestsSeen = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const db = admin.firestore();
  const metaRef = db.collection('users').doc(uid).collection('friendMeta').doc('meta');
  await metaRef.set(
    {
      lastSeenIncomingAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { status: 'ok' };
});

exports.changeUsername = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const newUsername = data && data.newUsername;
  if (typeof newUsername !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing username');
  }
  const target = newUsername.trim();
  const regex = /^[A-Za-z0-9 ]{3,20}$/;
  if (!regex.test(target)) {
    throw new functions.https.HttpsError('invalid-argument', 'username_invalid');
  }
  const lower = target.toLowerCase();
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);
  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'user_not_found');
    }
    const oldLower = userSnap.data().usernameLower;
    if (oldLower === lower) {
      return;
    }
    const mappingRef = db.collection('usernames').doc(lower);
    const mappingSnap = await tx.get(mappingRef);
    if (mappingSnap.exists && mappingSnap.data().uid !== uid) {
      throw new functions.https.HttpsError('already-exists', 'username_taken');
    }
    if (oldLower) {
      const oldRef = db.collection('usernames').doc(oldLower);
      tx.delete(oldRef);
    }
    tx.set(mappingRef, { uid, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    tx.update(userRef, { username: target, usernameLower: lower });
  });
  return { username: target, usernameLower: lower };
});
