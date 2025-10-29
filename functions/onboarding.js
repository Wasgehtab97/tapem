const functions = require('firebase-functions');
const admin = require('firebase-admin');

const MAX_MEMBER_NUMBER = 9999;

function formatMemberNumber(value) {
  const numeric = Number.parseInt(value, 10);
  if (Number.isNaN(numeric)) {
    return String(value || '').padStart(4, '0').slice(-4);
  }
  return String(numeric).padStart(4, '0');
}

exports.onGymMemberCreate = functions.firestore
  .document('gyms/{gymId}/users/{userId}')
  .onCreate(async (snap, context) => {
    const { gymId, userId } = context.params;
    const db = admin.firestore();
    const membershipRef = snap.ref;
    const onboardingRef = db.doc(`gyms/${gymId}/config/onboarding`);

    const initialData = snap.data() || {};
    const needsMemberNumber = !initialData.memberNumber;
    const needsCreatedAt = !initialData.createdAt;

    if (!needsMemberNumber && !needsCreatedAt) {
      functions.logger.debug('Membership already initialized', { gymId, userId });
      return null;
    }

    try {
      await db.runTransaction(async (tx) => {
        const freshSnap = await tx.get(membershipRef);
        const freshData = freshSnap.data() || {};
        const memberNumberMissing = !freshData.memberNumber;
        const createdAtMissing = !freshData.createdAt;

        if (needsMemberNumber && !memberNumberMissing) {
          functions.logger.warn('memberNumber already set before transaction', {
            gymId,
            userId,
          });
        }
        if (needsCreatedAt && !createdAtMissing) {
          functions.logger.warn('createdAt already set before transaction', {
            gymId,
            userId,
          });
        }

        if (!memberNumberMissing && !createdAtMissing) {
          functions.logger.debug('Membership already initialized inside transaction', {
            gymId,
            userId,
          });
          return;
        }

        let memberNumberValue = freshData.memberNumber;

        if (memberNumberMissing) {
          const onboardingSnap = await tx.get(onboardingRef);
          let nextMemberNumber = 1;
          if (onboardingSnap.exists) {
            const stored = onboardingSnap.get('nextMemberNumber');
            if (Number.isInteger(stored) && stored > 0) {
              nextMemberNumber = stored;
            }
          }

          if (nextMemberNumber > MAX_MEMBER_NUMBER) {
            functions.logger.error('Member number pool exhausted', {
              gymId,
              userId,
              nextMemberNumber,
            });
            throw new Error('Member number pool exhausted');
          }

          memberNumberValue = formatMemberNumber(nextMemberNumber);
          tx.set(
            onboardingRef,
            { nextMemberNumber: nextMemberNumber + 1 },
            { merge: true }
          );
        }

        const updates = {};
        if (memberNumberMissing && memberNumberValue) {
          updates.memberNumber = memberNumberValue;
        }
        if (createdAtMissing) {
          updates.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }

        if (Object.keys(updates).length === 0) {
          functions.logger.debug('No membership updates required', { gymId, userId });
          return;
        }

        tx.set(membershipRef, updates, { merge: true });
      });
    } catch (error) {
      functions.logger.error('Failed to assign member number', {
        gymId,
        userId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw error;
    }

    return null;
  });

exports._private = { formatMemberNumber };
