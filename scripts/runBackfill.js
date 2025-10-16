const admin = require('../functions/node_modules/firebase-admin');
const serviceAccount = require('./admin.json');
const { runBackfill } = require('../functions/dist/src/backfill/runtime');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function main() {
  console.log('Starte Dry-Run …');
  const preview = await runBackfill({ apply: false });
  console.log(JSON.stringify(preview, null, 2));

  console.log('Starte echten Lauf …');
  const applied = await runBackfill({ apply: true });
  console.log(JSON.stringify(applied, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
