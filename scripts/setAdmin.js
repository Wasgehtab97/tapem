// scripts/setAdmin.js

const admin = require('firebase-admin');

// Keyfile aus dem selben Ordner:
const serviceAccount = require('./admin.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// UID des Nutzers, der Admin werden soll:
const TEST_UID = 'BdEMGJkrE6MjGC9i3uH909MKCim1';

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
