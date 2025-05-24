// scripts/setAdmin.js

const admin = require('firebase-admin');

// Keyfile aus dem selben Ordner:
const serviceAccount = require('./24_05_gym02.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// UID des Nutzers, der Admin werden soll:
const TEST_UID = '3IK8kmaZfpX7ec1fng744H2px5y1';

async function makeAdmin() {
  try {
    // wir schreiben genau das Claim, das die Rules erwarten:
    await admin.auth().setCustomUserClaims(TEST_UID, { role: 'admin' });
    console.log(`✅ User ${TEST_UID} ist jetzt Admin (role: 'admin').`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Fehler beim Setzen des Admin-Claims:', err);
    process.exit(1);
  }
}

makeAdmin();
