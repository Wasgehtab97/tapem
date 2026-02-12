// functions/gymCodes.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

const GYM_ADMIN_ROLES = new Set(['admin', 'gymowner']);

/**
 * Generate a random, readable 6-character gym code
 * Excludes ambiguous characters: O/0, I/1, S/5, Z/2
 */
function generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

/**
 * Check if a code already exists in any gym_codes collection
 */
async function codeExists(code) {
    const snapshot = await admin.firestore()
        .collectionGroup('codes')
        .where('code', '==', code)
        .limit(1)
        .get();

    return !snapshot.empty;
}

/**
 * Generate a unique code (ensures no duplicates)
 */
async function generateUniqueCode(maxAttempts = 10) {
    for (let i = 0; i < maxAttempts; i++) {
        const code = generateCode();
        const exists = await codeExists(code);
        if (!exists) {
            return code;
        }
    }
    throw new Error(`Failed to generate unique code after ${maxAttempts} attempts`);
}

/**
 * Get the start of next month
 */
function getNextMonthStart() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth() + 1, 1);
}

/**
 * HTTP function to manually rotate a gym's code
 * Can be called by gym admins from the app (works on Spark plan!)
 */
exports.manuallyRotateGymCode = functions.https.onCall(async (data, context) => {
    // Check authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }

    const { gymId } = data;
    if (!gymId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'gymId is required'
        );
    }

    const db = admin.firestore();
    const userId = context.auth.uid;

    try {
        // Check if user is admin of this gym
        const membershipDoc = await db
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(userId)
            .get();

        const membershipRole = membershipDoc.data()?.role;
        if (!membershipDoc.exists || !GYM_ADMIN_ROLES.has(membershipRole)) {
            throw new functions.https.HttpsError(
                'permission-denied',
                'User is not an admin of this gym'
            );
        }

        // Generate new code
        const newCode = await generateUniqueCode();
        const now = admin.firestore.Timestamp.now();
        const expiresAt = getNextMonthStart();

        // Create new code
        await db
            .collection('gym_codes')
            .doc(gymId)
            .collection('codes')
            .add({
                code: newCode,
                gymId: gymId,
                createdAt: now,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                isActive: true,
                createdBy: userId
            });

        // Deactivate old codes
        const gracePeriod = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const oldCodesSnapshot = await db
            .collection('gym_codes')
            .doc(gymId)
            .collection('codes')
            .where('isActive', '==', true)
            .where('createdAt', '<', admin.firestore.Timestamp.fromDate(gracePeriod))
            .get();

        if (!oldCodesSnapshot.empty) {
            const batch = db.batch();
            oldCodesSnapshot.docs.forEach(doc => {
                batch.update(doc.ref, { isActive: false });
            });
            await batch.commit();
        }

        return {
            success: true,
            code: newCode,
            expiresAt: expiresAt.toISOString()
        };
    } catch (error) {
        console.error('Error in manuallyRotateGymCode:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
