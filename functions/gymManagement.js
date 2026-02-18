const functions = require('firebase-functions');
const admin = require('firebase-admin');

const STAFF_ROLES = new Set(['gymowner', 'admin']);

function assertAuthed(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Login erforderlich.'
    );
  }
}

async function ensureRemovalPermission({ db, context, gymId, targetUid }) {
  assertAuthed(context);
  const callerUid = context.auth.uid;
  const tokenRole = context.auth.token?.role || null;
  const tokenGymId = context.auth.token?.gymId || null;
  const isAppAdmin = tokenRole === 'admin';

  if (!isAppAdmin && callerUid === targetUid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Eigenes Konto kann nicht entfernt werden.'
    );
  }

  if (!isAppAdmin && tokenRole == 'gymowner' && tokenGymId && tokenGymId !== gymId) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'GymOwner darf nur Mitglieder im aktiven Gym verwalten.'
    );
  }

  const callerMembershipRef = db
    .collection('gyms')
    .doc(gymId)
    .collection('users')
    .doc(callerUid);
  const targetMembershipRef = db
    .collection('gyms')
    .doc(gymId)
    .collection('users')
    .doc(targetUid);

  const [callerMembershipSnap, targetMembershipSnap] = await Promise.all([
    callerMembershipRef.get(),
    targetMembershipRef.get(),
  ]);

  if (!targetMembershipSnap.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'Mitgliedschaft im Gym nicht gefunden.'
    );
  }

  if (!isAppAdmin) {
    const callerRole = callerMembershipSnap.data()?.role || null;
    const hasGymOwnerAccess = STAFF_ROLES.has(callerRole);
    if (!hasGymOwnerAccess && tokenRole !== 'gymowner') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Keine Berechtigung zum Entfernen von Mitgliedern.'
      );
    }
  }

  const targetRole = targetMembershipSnap.data()?.role || null;
  if (!isAppAdmin && STAFF_ROLES.has(targetRole)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Nur App-Admin darf Studio-Personal entfernen.'
    );
  }
}

async function deleteCollectionRecursive(collectionRef, batchSize = 200) {
  while (true) {
    const snap = await collectionRef.limit(batchSize).get();
    if (snap.empty) {
      return;
    }
    for (const doc of snap.docs) {
      // eslint-disable-next-line no-await-in-loop
      await deleteDocumentRecursive(doc.ref);
    }
  }
}

async function deleteDocumentRecursive(docRef) {
  const subcollections = await docRef.listCollections();
  for (const subcollection of subcollections) {
    // eslint-disable-next-line no-await-in-loop
    await deleteCollectionRecursive(subcollection);
  }
  await docRef.delete().catch(() => {});
}

async function removeGymIdFromUser({ db, gymId, targetUid }) {
  const userRef = db.collection('users').doc(targetUid);
  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'User nicht gefunden.');
    }

    const userData = userSnap.data() || {};
    const gymCodesRaw = Array.isArray(userData.gymCodes) ? userData.gymCodes : [];
    const gymCodes = gymCodesRaw.filter((code) => typeof code === 'string');
    const nextGymCodes = gymCodes.filter((code) => code !== gymId);

    const updates = {
      gymCodes: nextGymCodes,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (userData.activeGymId === gymId) {
      if (nextGymCodes.length === 1) {
        updates.activeGymId = nextGymCodes[0];
      } else {
        updates.activeGymId = admin.firestore.FieldValue.delete();
      }
    }
    tx.set(userRef, updates, { merge: true });
  });
}

exports.removeUserFromGym = functions.https.onCall(async (data, context) => {
  const gymId = (data?.gymId || '').toString().trim();
  const targetUid = (data?.uid || '').toString().trim();
  if (!gymId || !targetUid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'gymId und uid sind erforderlich.'
    );
  }

  const db = admin.firestore();
  await ensureRemovalPermission({ db, context, gymId, targetUid });

  await removeGymIdFromUser({ db, gymId, targetUid });

  const membershipRef = db
    .collection('gyms')
    .doc(gymId)
    .collection('users')
    .doc(targetUid);
  await deleteDocumentRecursive(membershipRef);

  const devicesSnap = await db.collection('gyms').doc(gymId).collection('devices').get();
  for (const deviceDoc of devicesSnap.docs) {
    const leaderboardRef = deviceDoc.ref.collection('leaderboard').doc(targetUid);
    // eslint-disable-next-line no-await-in-loop
    await deleteDocumentRecursive(leaderboardRef);
  }

  await db
    .collection('gyms')
    .doc(gymId)
    .collection('adminAudit')
    .add({
      action: 'remove_user_from_gym',
      actorUid: context.auth.uid,
      targetUid,
      gymId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return { ok: true, gymId, uid: targetUid };
});
