#!/usr/bin/env node
/**
 * Synchronisiert die Muskelgruppen eines Prod-Gyms auf den Stand eines Dev-Gyms
 * und bereinigt Geräte-Bezüge (muscleGroupIds, primary/secondaryMuscleGroups).
 *
 * Aufruf (dry-run):
 *   DEV_KEY=./admin-dev.json PROD_KEY=./admin.json DEV_GYM=lifthouse_dev PROD_GYM=lifthouse_koblenz node scripts/sync_muscle_groups_prod.js
 *
 * Ausführen (schreibend):
 *   ... node scripts/sync_muscle_groups_prod.js --apply
 *
 * Es werden ausschließlich:
 *  - Die Collection gyms/{PROD_GYM}/muscleGroups ersetzt (Delete + Set mit Dev-Stand)
 *  - An Geräten die Felder muscleGroupIds/muscleGroups/primaryMuscleGroups/secondaryMuscleGroups auf gültige IDs gemappt.
 * Sonst nichts.
 */

const admin = require('firebase-admin');
const path = require('path');

const DEV_KEY = process.env.DEV_KEY || './admin-dev.json';
const PROD_KEY = process.env.PROD_KEY || './admin.json';
const DEV_GYM = process.env.DEV_GYM;
const PROD_GYM = process.env.PROD_GYM;
const APPLY = process.argv.includes('--apply');

if (!DEV_GYM || !PROD_GYM) {
  console.error('❌ Bitte DEV_GYM und PROD_GYM per Env setzen.');
  process.exit(1);
}

function loadApp(name, keyFile) {
  const full = path.isAbsolute(keyFile) ? keyFile : path.resolve(process.cwd(), keyFile);
  const svc = require(full);
  return admin.initializeApp(
    {
      credential: admin.credential.cert(svc),
    },
    name
  );
}

const devDb = loadApp('dev', DEV_KEY).firestore();
const prodDb = loadApp('prod', PROD_KEY).firestore();

function normalizeList(val) {
  if (!val) return [];
  if (Array.isArray(val)) return val.map(String).map((v) => v.trim()).filter(Boolean);
  if (typeof val === 'string') return val.split(',').map((v) => v.trim()).filter(Boolean);
  if (typeof val === 'object') return Object.values(val).map((v) => String(v)).map((v) => v.trim()).filter(Boolean);
  return [];
}

function uniq(list) {
  return Array.from(new Set(list.filter(Boolean)));
}

async function fetchMuscleGroups(db, gymId) {
  const snap = await db.collection('gyms').doc(gymId).collection('muscleGroups').get();
  return snap.docs.map((d) => ({ id: d.id, data: d.data() }));
}

async function fetchDevices(db, gymId) {
  const snap = await db.collection('gyms').doc(gymId).collection('devices').get();
  return snap.docs.map((d) => ({ id: d.id, data: d.data() }));
}

function buildMapper(devGroups) {
  const devIds = new Set(devGroups.map((g) => g.id));
  const nameToId = new Map();
  devGroups.forEach((g) => {
    if (g.data?.name) {
      nameToId.set(String(g.data.name).toLowerCase(), g.id);
    }
  });
  return function mapToDevId(raw) {
    if (!raw) return null;
    const v = String(raw).trim();
    const lower = v.toLowerCase();
    if (devIds.has(v)) return v;
    if (devIds.has(lower)) return lower;
    if (nameToId.has(lower)) return nameToId.get(lower);
    return null;
  };
}

async function replaceMuscleGroups(devGroups, prodGymId) {
  const ref = prodDb.collection('gyms').doc(prodGymId).collection('muscleGroups');
  const existing = await ref.get();
  if (!APPLY) {
    console.log(
      `Dry-run: würde ${existing.size} bestehende Muskelgruppen löschen und ${devGroups.length} aus Dev schreiben.`
    );
    return;
  }
  const batch = prodDb.batch();
  existing.forEach((doc) => batch.delete(doc.ref));
  devGroups.forEach((g) => {
    batch.set(ref.doc(g.id), g.data || {});
  });
  await batch.commit();
  console.log(`✅ Muskelgruppen ersetzt: gelöscht ${existing.size}, geschrieben ${devGroups.length}`);
}

async function fixDevices(devGroups, prodGymId) {
  const mapper = buildMapper(devGroups);
  const validIds = new Set(devGroups.map((g) => g.id));
  const devices = await fetchDevices(prodDb, prodGymId);
  let updates = 0;
  let untouched = 0;
  const problems = [];

  for (const { id: docId, data } of devices) {
    const primaryRaw = normalizeList(data.primaryMuscleGroups);
    const secondaryRaw = normalizeList(data.secondaryMuscleGroups);
    const fallbackAll = normalizeList(data.muscleGroupIds || data.muscleGroups);

    const mapList = (list) => uniq(list.map(mapper).filter(Boolean));
    const primary = mapList(primaryRaw);
    const secondary = mapList(secondaryRaw);
    const combined = uniq([...primary, ...secondary, ...mapList(fallbackAll)]);

    const currentCombined = uniq(normalizeList(data.muscleGroupIds));

    const needsUpdate =
      JSON.stringify(combined) !== JSON.stringify(currentCombined) ||
      JSON.stringify(primary) !== JSON.stringify(normalizeList(data.primaryMuscleGroups)) ||
      JSON.stringify(secondary) !== JSON.stringify(normalizeList(data.secondaryMuscleGroups));

    if (!combined.length && (primaryRaw.length || secondaryRaw.length || fallbackAll.length)) {
      problems.push({ docId, reason: 'alle Gruppen unbekannt – bleibt leer' });
    }

    if (needsUpdate && APPLY) {
      await prodDb
        .collection('gyms')
        .doc(prodGymId)
        .collection('devices')
        .doc(docId)
        .update({
          muscleGroupIds: combined,
          muscleGroups: combined,
          primaryMuscleGroups: primary,
          secondaryMuscleGroups: secondary,
        })
        .catch((err) => {
          problems.push({ docId, reason: `update failed: ${err.message}` });
        });
      updates++;
    } else if (needsUpdate && !APPLY) {
      updates++;
    } else {
      untouched++;
    }
  }

  if (APPLY) {
    console.log(`✅ Geräte aktualisiert: ${updates} geändert, ${untouched} unverändert`);
  } else {
    console.log(`Dry-run: würde ${updates} Geräte ändern, ${untouched} unverändert lassen`);
  }
  if (problems.length) {
    console.warn('⚠️  Hinweise/Probleme:', problems.slice(0, 20));
    if (problems.length > 20) console.warn(`… weitere ${problems.length - 20} ausgelassen`);
  }
}

async function main() {
  console.log('Starte Sync Muskelgruppen (Dev → Prod)');
  console.log(`DEV_GYM=${DEV_GYM}, PROD_GYM=${PROD_GYM}, apply=${APPLY ? 'yes' : 'no (dry-run)'}`);
  const devGroups = await fetchMuscleGroups(devDb, DEV_GYM);
  console.log(`Dev-Gruppen: ${devGroups.length}`);
  await replaceMuscleGroups(devGroups, PROD_GYM);
  await fixDevices(devGroups, PROD_GYM);
  console.log('Fertig.');
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Fehler:', err);
  process.exit(1);
});
