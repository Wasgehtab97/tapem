// copy_gym_lifthouse.mjs
// Kopiert gyms/gym_01 -> gyms/lifthouse_koblenz inkl. ALLER Subcollections.
// Optional: --dry-run  --overwrite
// Auth: GOOGLE_APPLICATION_CREDENTIALS auf SA-JSON setzen oder ./sa.json bereitstellen.

import admin from "firebase-admin";
import fs from "node:fs";
import path from "node:path";

const SA =
  (process.env.GOOGLE_APPLICATION_CREDENTIALS &&
    fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS) &&
    process.env.GOOGLE_APPLICATION_CREDENTIALS) ||
  (fs.existsSync("./sa.json") && path.resolve("./sa.json"));

if (!SA) {
  console.error("❌ Service Account nicht gefunden. Setze GOOGLE_APPLICATION_CREDENTIALS oder lege ./sa.json ab.");
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(SA) });
const db = admin.firestore();

const SRC_ID = "gym_01";
const DST_ID = "lifthouse_koblenz";

const args = process.argv.slice(2);
const DRY_RUN = args.includes("--dry-run");
const OVERWRITE = args.includes("--overwrite");

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function copyDocDeep(srcDocRef, dstDocRef, transform, depth = 0) {
  const pad = "  ".repeat(depth);
  const snap = await srcDocRef.get();
  if (!snap.exists) throw new Error(`Quelle fehlt: ${srcDocRef.path}`);

  const data = transform(snap.data(), srcDocRef, dstDocRef);
  if (DRY_RUN) {
    console.log(pad + `⏭️  (dry-run) set ${dstDocRef.path}`);
  } else {
    if (!OVERWRITE && (await dstDocRef.get()).exists && depth === 0) {
      throw new Error(`Ziel existiert bereits: ${dstDocRef.path} (ohne --overwrite abgebrochen)`);
    }
    await dstDocRef.set(data, { merge: false });
    console.log(pad + `✅ set ${dstDocRef.path}`);
  }

  const subs = await srcDocRef.listCollections();
  for (const sub of subs) {
    const snap = await sub.get();
    if (snap.empty) continue;
    console.log(pad + `📂 ${sub.id} (${snap.size})`);
    for (const doc of snap.docs) {
      await copyDocDeep(doc.ref, dstDocRef.collection(sub.id).doc(doc.id), transform, depth + 1);
      if (!DRY_RUN) await sleep(5);
    }
  }
}

function rootTransformFactory(srcRoot, dstId) {
  return (data, srcRef) => {
    // Nur am Root: slug spiegeln, code möglichst beibehalten (Fallback: dstId)
    if (srcRef.path === srcRoot.path) {
      return {
        ...data,
        slug: dstId,
        code: data.code ?? dstId,
      };
    }
    return data;
  };
}

(async () => {
  const srcRef = db.collection("gyms").doc(SRC_ID);
  const dstRef = db.collection("gyms").doc(DST_ID);

  console.log(`➡️  Kopiere ${srcRef.path}  →  ${dstRef.path} ${DRY_RUN ? "[dry-run]" : ""} ${OVERWRITE ? "[overwrite]" : ""}`);

  try {
    await copyDocDeep(srcRef, dstRef, rootTransformFactory(srcRef, DST_ID));
    console.log(`✨ Fertig: ${srcRef.path} → ${dstRef.path}`);
  } catch (e) {
    console.error("❌ Fehler:", e.message);
    process.exit(2);
  }

  console.log("🏁 Done.");
  process.exit(0);
})();
