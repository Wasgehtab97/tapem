const functions = require('firebase-functions');
const admin = require('firebase-admin');

function applyXp({ xp, level, add, maxLevel = 30, threshold = 1000 }) {
  if (level >= maxLevel) {
    return { xp: 0, level: maxLevel, leveledUp: false };
  }
  let newXp = xp + add;
  let newLevel = level;
  let leveledUp = false;
  while (newXp >= threshold && newLevel < maxLevel) {
    newXp -= threshold;
    newLevel += 1;
    leveledUp = true;
  }
  if (newLevel >= maxLevel) {
    newLevel = maxLevel;
    newXp = 0;
  }
  return { xp: newXp, level: newLevel, leveledUp };
}

exports.applyXp = applyXp;

exports.grantXpForSession = functions.https.onCall(async (data, context) => {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const sessionId = data.sessionId;
  const gymId = data.gymId;
  const deviceId = data.deviceId;
  const isMulti = !!data.isMulti;
  const primaryMuscles = Array.isArray(data.primaryMuscles) ? data.primaryMuscles : [];
  const secondaryMuscles = Array.isArray(data.secondaryMuscles) ? data.secondaryMuscles : [];

  if (typeof sessionId !== 'string' || typeof gymId !== 'string' || typeof deviceId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing ids');
  }

  const db = admin.firestore();
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');

  const markerCol = db.collection('users').doc(uid).collection('xp_markers');

  return await db.runTransaction(async (tx) => {
    const awards = [];

    // Daily XP
    const dailyMarkerId = `${uid}:${date}`;
    const dailyMarkerRef = markerCol.doc(dailyMarkerId);
    const dailyMarkerSnap = await tx.get(dailyMarkerRef);
    if (!dailyMarkerSnap.exists) {
      const dayRef = db.collection('users').doc(uid).collection('trainingDayXP').doc(date);
      const daySnap = await tx.get(dayRef);
      const dayData = daySnap.exists ? daySnap.data() : { xp: 0, level: 1 };
      const applied = applyXp({ xp: dayData.xp || 0, level: dayData.level || 1, add: 50 });
      tx.set(dayRef, { xp: applied.xp, level: applied.level }, { merge: true });
      tx.set(dailyMarkerRef, { createdAt: admin.firestore.FieldValue.serverTimestamp() });
      awards.push({ scope: 'daily', amount: 50 });
    }

    // Device XP
    const deviceSessionMarker = `${uid}:${deviceId}:${sessionId}`;
    const deviceSessionRef = markerCol.doc(deviceSessionMarker);
    const deviceSessionSnap = await tx.get(deviceSessionRef);
    if (!deviceSessionSnap.exists) {
      let amount = 50;
      if (!isMulti) {
        const deviceDayMarkerId = `${uid}:${deviceId}:${date}`;
        const deviceDayMarkerRef = markerCol.doc(deviceDayMarkerId);
        const deviceDaySnap = await tx.get(deviceDayMarkerRef);
        const already = deviceDaySnap.exists ? deviceDaySnap.data().xp || 0 : 0;
        const cap = 50;
        if (already >= cap) {
          amount = 0;
        } else {
          amount = Math.min(50, cap - already);
          tx.set(
            deviceDayMarkerRef,
            { xp: already + amount, createdAt: admin.firestore.FieldValue.serverTimestamp() },
            { merge: true }
          );
        }
      }
      if (amount > 0) {
        const lbRef = db
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(deviceId)
          .collection('leaderboard')
          .doc(uid);
        const lbSnap = await tx.get(lbRef);
        const lbData = lbSnap.exists ? lbSnap.data() : { xp: 0, level: 1 };
        const applied = applyXp({ xp: lbData.xp || 0, level: lbData.level || 1, add: amount });
        tx.set(
          lbRef,
          {
            xp: applied.xp,
            level: applied.level,
            lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        tx.set(deviceSessionRef, { createdAt: admin.firestore.FieldValue.serverTimestamp() });
        awards.push({ scope: 'device', amount, deviceId, isMulti });
      }
    }

    // Muscle XP
    const muscles = [];
    for (const m of primaryMuscles) muscles.push({ id: m, amount: 50 });
    for (const m of secondaryMuscles) muscles.push({ id: m, amount: 10 });

    for (const m of muscles) {
      const markerId = `${uid}:${m.id}:${sessionId}`;
      const markerRef = markerCol.doc(markerId);
      const markerSnap = await tx.get(markerRef);
      if (markerSnap.exists) continue;
      const musRef = db.collection('users').doc(uid).collection('muscles').doc(m.id);
      const musSnap = await tx.get(musRef);
      const musData = musSnap.exists ? musSnap.data() : { xp: 0, level: 1 };
      const applied = applyXp({ xp: musData.xp || 0, level: musData.level || 1, add: m.amount });
      tx.set(
        musRef,
        {
          xp: applied.xp,
          level: applied.level,
          lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(markerRef, { createdAt: admin.firestore.FieldValue.serverTimestamp() });
      awards.push({ scope: 'muscle', amount: m.amount, muscleId: m.id });
    }

    return { awards };
  });
});

