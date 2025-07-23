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
    if (!userId || !sessionId) return null;

    const db = admin.firestore();
    const existing = await snap.ref.parent
      .where('sessionId', '==', sessionId)
      .get();
    if (existing.size > 1) return null;

    const now = admin.firestore.Timestamp.now();
    const weeklyRef = db
      .collection('gyms')
      .doc(gymId)
      .collection('weekly')
      .where('start', '<=', now)
      .where('end', '>=', now);
    const monthlyRef = db
      .collection('gyms')
      .doc(gymId)
      .collection('monthly')
      .where('start', '<=', now)
      .where('end', '>=', now);

    const [weeklySnap, monthlySnap] = await Promise.all([weeklyRef.get(), monthlyRef.get()]);
    const challenges = [...weeklySnap.docs, ...monthlySnap.docs];

    for (const doc of challenges) {
      const ch = doc.data();
      const devices = ch.deviceIds || [];
      if (devices.length && !devices.includes(deviceId)) continue;

      const logsSnap = await db
        .collectionGroup('logs')
        .where('userId', '==', userId)
        .where('deviceId', 'in', devices.length ? devices : [deviceId])
        .where('timestamp', '>=', ch.start)
        .where('timestamp', '<=', ch.end)
        .get();

      if (logsSnap.size >= (ch.minSets || 0)) {
        const badgeRef = db
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(doc.id);
        await db.runTransaction(async (tx) => {
          const badgeSnap = await tx.get(badgeRef);
          if (!badgeSnap.exists) {
            tx.set(badgeRef, {
              challengeId: doc.id,
              awardedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            const statsRef = db
              .collection('gyms')
              .doc(gymId)
              .collection('users')
              .doc(userId)
              .collection('rank')
              .doc('stats');
            const statsSnap = await tx.get(statsRef);
            const xp = (statsSnap.data()?.challengeXP || 0) + (ch.xpReward || 0);
            if (statsSnap.exists) {
              tx.update(statsRef, { challengeXP: xp });
            } else {
              tx.set(statsRef, { challengeXP: xp });
            }
          }
        });
      }
    }
    return null;
  });
