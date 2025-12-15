// functions/push.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Callable function to register an FCM token for the current user.
 *
 * This works on the free (Spark) plan because it is an HTTPS callable
 * without Cloud Scheduler or other paid features.
 *
 * The client calls this from initializePushMessaging with:
 *   { token: string, platform: 'ios' | 'android' | 'web' | ... }
 *
 * Tokens are stored under:
 *   users/{uid}/pushTokens/{token}
 */
exports.registerPushToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to register a push token',
    );
  }

  const token = (data && data.token) || null;
  const platform = (data && data.platform) || 'unknown';

  if (!token || typeof token !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Field "token" (string) is required',
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();
  const ref = db.collection('users').doc(uid).collection('pushTokens').doc(token);

  await ref.set(
    {
      token,
      platform,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { success: true };
});

/**
 * Helper to send a notification to all registered tokens of a user.
 *
 * This can be re-used by event-based triggers (friend requests, chat, coaching).
 */
async function sendNotificationToUser(userId, notification, data) {
  const db = admin.firestore();
  const tokensSnap = await db
    .collection('users')
    .doc(userId)
    .collection('pushTokens')
    .get();

  if (tokensSnap.empty) {
    console.log(`[Push] No tokens for user ${userId}`);
    return;
  }

  const tokens = tokensSnap.docs.map((d) => d.id);

  const message = {
    tokens,
    notification,
    data: data || {},
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  console.log(
    `[Push] Sent notification to user ${userId}: success=${response.successCount} failure=${response.failureCount}`,
  );
}

/**
 * Event-based push: new friend request
 *
 * Triggered when a document is created in friendRequests/{reqId}.
 * Sends a push notification to the recipient (toUserId).
 */
exports.onFriendRequestCreated = functions.firestore
  .document('friendRequests/{reqId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const toUserId = data.toUserId;
    const fromUserId = data.fromUserId;

    if (!toUserId || !fromUserId) {
      console.log('[Push] friendRequests missing toUserId/fromUserId, skipping');
      return null;
    }

    const notification = {
      title: 'Neue Freundschaftsanfrage',
      body: 'Jemand möchte sich mit dir verbinden.',
    };

    const extraData = {
      action: 'open_requests',
      fromUserId,
      type: 'friend_request',
    };

    await sendNotificationToUser(toUserId, notification, extraData);
    return null;
  });

/**
 * Event-based push: new chat message
 *
 * Triggered when a message is created under
 * friendConversations/{conversationId}/messages/{messageId}.
 * Sends a push notification to the other member of the conversation.
 */
exports.onFriendChatMessageCreated = functions.firestore
  .document('friendConversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const conversationId = context.params.conversationId;
    const senderId = data.senderId;

    if (!conversationId || !senderId) {
      console.log('[Push] chat message missing conversationId/senderId, skipping');
      return null;
    }

    const parts = conversationId.split('_');
    if (parts.length !== 2) {
      console.log(`[Push] Unexpected conversationId format: ${conversationId}`);
      return null;
    }

    const uid1 = parts[0];
    const uid2 = parts[1];
    const recipientId = senderId === uid1 ? uid2 : uid1;

    // Do not send notifications to the sender themselves
    if (!recipientId || recipientId === senderId) {
      return null;
    }

    const text = (data.text || '').toString();
    const notification = {
      title: 'Neue Nachricht',
      body: text.length > 0 ? text.substring(0, 80) : 'Neue Chat-Nachricht',
    };

    const extraData = {
      action: 'open_friend',
      uid: senderId,
      type: 'friend_chat',
      conversationId,
    };

    await sendNotificationToUser(recipientId, notification, extraData);
    return null;
  });

