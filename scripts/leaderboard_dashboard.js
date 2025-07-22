const admin = require('firebase-admin');
const WebSocket = require('ws');

admin.initializeApp();
const db = admin.firestore();

const wss = new WebSocket.Server({ port: 8081 });


async function fetchEntries(col) {
  const snap = await col.orderBy('xp','desc').get();
  const arr = [];
  for (const doc of snap.docs) {
    const user = await db.collection('users').doc(doc.id).get();
    arr.push({ userId: doc.id, username: user.data()?.username, ...doc.data() });
  }
  return arr;
}

async function broadcast() {
  const col = db.collection('leaderboards_global');
  const entries = await fetchEntries(col);
  const payload = JSON.stringify({ type: 'global', data: entries });
  for (const client of wss.clients) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(payload);
    }
  }
}

wss.on('connection', () => broadcast());

setInterval(broadcast, 30000);
console.log('Dashboard WebSocket running on ws://localhost:8081');
