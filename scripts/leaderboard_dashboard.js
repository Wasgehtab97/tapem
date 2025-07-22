const admin = require('firebase-admin');
const WebSocket = require('ws');

admin.initializeApp();
const db = admin.firestore();

const wss = new WebSocket.Server({ port: 8081 });

function weekId(date) {
  const d = new Date(date.getTime());
  d.setUTCDate(d.getUTCDate() - d.getUTCDay() + 4);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1));
  const week = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-${String(week).padStart(2,'0')}`;
}

function monthId(date) {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth()+1).padStart(2,'0')}`;
}

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
  const now = new Date();
  const wRef = db.collection('leaderboards_weekly').doc(weekId(now)).collection('users');
  const mRef = db.collection('leaderboards_monthly').doc(monthId(now)).collection('users');
  const [weekly, monthly] = await Promise.all([fetchEntries(wRef), fetchEntries(mRef)]);
  const payloadW = JSON.stringify({ type: 'weekly', data: weekly });
  const payloadM = JSON.stringify({ type: 'monthly', data: monthly });
  for (const client of wss.clients) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(payloadW);
      client.send(payloadM);
    }
  }
}

wss.on('connection', () => broadcast());

setInterval(broadcast, 30000);
console.log('Dashboard WebSocket running on ws://localhost:8081');
