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
      .collection(`gyms/${gymId}/challenges/weekly`)
      .where('start', '<=', now)
      .where('end', '>=', now);
    const monthlyRef = db
      .collection(`gyms/${gymId}/challenges/monthly`)
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

      const logsSnap = await db
        .collectionGroup('logs')
        .where('userId', '==', userId)
        .where('deviceId', 'in', devices.length ? devices : [deviceId])
        .where('timestamp', '>=', ch.start)
        .where('timestamp', '<=', ch.end)
        .get();

      console.log(
        `📊 challenge ${doc.id} requires ${ch.minSets || 0} sets -> ${logsSnap.size} logs`
      );
      console.log(
        `📈 challenge ${doc.id} progress ${logsSnap.size}/${ch.minSets || 0}`
      );
      if (logsSnap.size >= (ch.minSets || 0)) {
        const completedRef = db
          .collection(`gyms/${gymId}/users/${userId}/completedChallenges`)
          .doc(doc.id);
        const badgeRef = db
          .collection('users')
          .doc(userId)
          .collection('badges')
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

            console.log(`📄 completedChallenge doc ${completedRef.path}`);

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
            tx.set(badgeRef, {
              challengeId: doc.id,
              userId,
              awardedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(
              `🏁 challenge ${doc.id} completed by ${userId}, +${ch.xpReward || 0} XP`
            );
          }
        });
      }
    }
    return null;
  });