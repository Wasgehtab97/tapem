const functions = require('firebase-functions');
const admin = require('firebase-admin');

function requireAdminContext(context, targetGymId) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login erforderlich.');
  }
  const role = context.auth.token.role;
  const gymIdClaim = context.auth.token.gymId || null;
  const allowed = role === 'admin' || role === 'gymowner';
  if (!allowed) {
    throw new functions.https.HttpsError('permission-denied', 'Kein Admin.');
  }
  if (role === 'gymowner' && targetGymId && gymIdClaim && targetGymId !== gymIdClaim) {
    throw new functions.https.HttpsError('permission-denied', 'GymOwner darf nur eigenes Gym sehen.');
  }
  return { role, gymIdClaim };
}

exports.adminListGyms = functions.https.onCall(async (data, context) => {
  const limit = Math.min(parseInt(data?.limit, 10) || 20, 100);
  const { role, gymIdClaim } = requireAdminContext(context, data?.gymId || null);
  const db = admin.firestore();

  try {
    let ref = db.collection('gyms');
    if (role === 'gymowner' && gymIdClaim) {
      ref = ref.where(admin.firestore.FieldPath.documentId(), '==', gymIdClaim);
    }
    const snap = await ref.limit(limit).get();
    const gyms = snap.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() || {}),
    }));
    return { gyms };
  } catch (err) {
    console.error('adminListGyms error', err);
    throw new functions.https.HttpsError('internal', 'Fehler beim Laden der Gyms');
  }
});

exports.adminListUsers = functions.https.onCall(async (data, context) => {
  const { role, gymIdClaim } = requireAdminContext(context, data?.gymId || null);
  const db = admin.firestore();
  const limit = Math.min(parseInt(data?.limit, 10) || 20, 100);

  try {
    let ref = db.collection('users');
    if (role === 'gymowner' && gymIdClaim) {
      ref = ref.where('gymCodes', 'array-contains', gymIdClaim);
    }
    const snap = await ref.limit(limit).get();
    const users = snap.docs.map((doc) => ({
      id: doc.id,
      email: doc.data()?.email || null,
      username: doc.data()?.username || null,
      gymCodes: doc.data()?.gymCodes || [],
      role: doc.data()?.role || null,
    }));
    return { users };
  } catch (err) {
    console.error('adminListUsers error', err);
    throw new functions.https.HttpsError('internal', 'Fehler beim Laden der Nutzer');
  }
});
