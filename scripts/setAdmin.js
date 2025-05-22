// scripts/setAdmin.js
const admin = require('firebase-admin');

// Pfad zum JSON-Key im selben Verzeichnis:
const serviceAccount = require(
  './tap-em-firebase-adminsdk-fbsvc-6b462e1c12.json'
);

// Admin SDK initialisieren
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Hier deine Test-User-UID eintragen:
const TEST_UID = 'DrzaD8BdIcOwumgmuYSVMj0ESAC3';

async function makeAdmin() {
  try {
    await admin.auth().setCustomUserClaims(TEST_UID, { role: 'admin' });
    console.log(`✅ User ${TEST_UID} wurde zum Admin ernannt.`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Fehler beim Setzen des Admin-Claims:', err);
    process.exit(1);
  }
}

makeAdmin();
