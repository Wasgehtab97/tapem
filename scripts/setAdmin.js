// scripts/setAdmin.js
// Setzt einen Custom-Claim für einen bestehenden User (Dev-Project).
// Voraussetzung: serviceAccount JSON liegt als scripts/admin.json.

const admin = require('firebase-admin');
const path = require('path');

const keyFile = process.env.ADMIN_KEY_FILE || './admin-dev.json';
const serviceAccount = require(path.resolve(__dirname, keyFile));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Achtung: Shell-Variable UID ist reserviert. Daher CLAIM_UID nutzen.
const TARGET_UID = process.env.CLAIM_UID || null;
const TARGET_EMAIL = process.env.EMAIL || null;
const ROLE = process.env.ROLE || 'global_admin';
const GYM_ID = process.env.GYM_ID || null;

async function makeAdmin() {
  try {
    if (!TARGET_UID && !TARGET_EMAIL) {
      throw new Error('Bitte UID oder EMAIL per Env setzen: UID=<uid> oder EMAIL=<mail>');
    }
    let userRecord = null;
    if (TARGET_UID) {
      userRecord = await admin.auth().getUser(TARGET_UID);
    } else if (TARGET_EMAIL) {
      userRecord = await admin.auth().getUserByEmail(TARGET_EMAIL).catch(async (err) => {
        if (err.code === 'auth/user-not-found') {
          // User fehlt? Erstellen mit Platzhalter-Passwort (muss danach geändert werden).
          return admin.auth().createUser({
            email: TARGET_EMAIL,
            password: Math.random().toString(36).slice(-12),
            emailVerified: false,
            disabled: false,
          });
        }
        throw err;
      });
    }
    if (!userRecord) {
      throw new Error('UserRecord nicht gefunden/erstellt.');
    }

    const claims = GYM_ID ? { role: ROLE, gymId: GYM_ID } : { role: ROLE };
    await admin.auth().setCustomUserClaims(userRecord.uid, claims);
    console.log(
      `✅ User ${userRecord.email || userRecord.uid} (${userRecord.uid}) ist jetzt ${ROLE}${
        GYM_ID ? ` (gymId=${GYM_ID})` : ''
      }.`
    );
    process.exit(0);
  } catch (err) {
    console.error('❌ Fehler beim Setzen des Claims:', err);
    process.exit(1);
  }
}

makeAdmin();
