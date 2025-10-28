const functions = require('firebase-functions');
const admin = require('firebase-admin');

const MAX_MEMBER_NUMBER = 9999;
const MEMBER_NUMBER_LENGTH = 4;

async function assignMemberNumberHandler({
  snap,
  context,
  firestore,
  fieldValue,
  logger,
}) {
  const { gymId, userId } = context.params;
  const memberRef = snap.ref;
  const configRef = firestore
    .collection('gyms')
    .doc(gymId)
    .collection('config')
    .doc('onboarding');

  const serverTimestamp = fieldValue.serverTimestamp;

  await firestore.runTransaction(async (tx) => {
    const latestMemberSnap = await tx.get(memberRef);
    const currentData = latestMemberSnap.data() || {};
    if (currentData.memberNumber) {
      logger?.debug?.('member_number_exists', {
        gymId,
        userId,
        memberNumber: currentData.memberNumber,
      });
      return;
    }

    const configSnap = await tx.get(configRef);
    const configData = configSnap.exists ? configSnap.data() || {} : {};
    let nextNumber = 1;
    if (typeof configData.nextMemberNumber === 'number' && configData.nextMemberNumber > 0) {
      nextNumber = configData.nextMemberNumber;
    }

    if (nextNumber > MAX_MEMBER_NUMBER) {
      logger?.error?.('member_number_limit_reached', { gymId, userId, nextNumber });
      tx.set(
        configRef,
        {
          limitReachedAt: serverTimestamp(),
          nextMemberNumber: nextNumber,
        },
        { merge: true }
      );
      return;
    }

    const formatted = String(nextNumber).padStart(MEMBER_NUMBER_LENGTH, '0');

    tx.update(memberRef, {
      memberNumber: formatted,
      onboardingAssignedAt: serverTimestamp(),
    });
    tx.set(
      configRef,
      {
        nextMemberNumber: nextNumber + 1,
        lastAssignedNumber: formatted,
        updatedAt: serverTimestamp(),
      },
      { merge: true }
    );

    logger?.info?.('member_number_assigned', {
      gymId,
      userId,
      memberNumber: formatted,
    });
  });
}

const assignMemberNumber = functions.firestore
  .document('gyms/{gymId}/users/{userId}')
  .onCreate(async (snap, context) => {
    const firestore = admin.firestore();
    await assignMemberNumberHandler({
      snap,
      context,
      firestore,
      fieldValue: admin.firestore.FieldValue,
      logger: functions.logger,
    });
  });

module.exports = {
  assignMemberNumber,
  assignMemberNumberHandler,
  MAX_MEMBER_NUMBER,
  MEMBER_NUMBER_LENGTH,
};
