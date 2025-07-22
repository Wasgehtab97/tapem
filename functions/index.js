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
