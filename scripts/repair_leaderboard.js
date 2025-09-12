#!/usr/bin/env node
// Repair leaderboard documents by ensuring required fields exist.
// Usage: node scripts/repair_leaderboard.js <gymId> <deviceId>

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const credPath = path.join(__dirname, 'admin.example.json');
if (!fs.existsSync(credPath)) {
  console.error('Missing admin credential file at', credPath);
  process.exit(1);
}
const serviceAccount = require(credPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function repair(gymId, deviceId) {
  const db = admin.firestore();
  const col = db
    .collection('gyms')
    .doc(gymId)
    .collection('devices')
    .doc(deviceId)
    .collection('leaderboard');

  const snap = await col.get();
  for (const doc of snap.docs) {
    const data = doc.data();
    const updates = {};
    if (!('userId' in data)) updates.userId = doc.id;
    if (!('xp' in data)) updates.xp = 0;
    if (!('level' in data)) updates.level = 1;
    if (Object.keys(updates).length) {
      console.log('Repairing', doc.ref.path, updates);
      await doc.ref.set(updates, { merge: true });
    }
  }
}

const [gymId, deviceId] = process.argv.slice(2);
if (!gymId || !deviceId) {
  console.error('Usage: node scripts/repair_leaderboard.js <gymId> <deviceId>');
  process.exit(1);
}

repair(gymId, deviceId)
  .then(() => {
    console.log('Done');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Error', err);
    process.exit(1);
  });
