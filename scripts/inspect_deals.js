// scripts/inspect_deals.js
const admin = require('firebase-admin');
const path = require('path');
const keyFile = process.env.ADMIN_KEY_FILE || './admin-dev.json';
const serviceAccount = require(path.resolve(__dirname, keyFile));

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}
const db = admin.firestore();

async function inspect() {
    console.log('🔍 Inspecting Deals in', serviceAccount.project_id);
    const snapshot = await db.collection('deals').get();
    if (snapshot.empty) {
        console.log('❌ No deals found.');
    } else {
        console.log(`✅ Found ${snapshot.size} deals:`);
        snapshot.forEach(doc => {
            console.log(`- ID: ${doc.id}`);
            console.log(JSON.stringify(doc.data(), null, 2));
        });
    }
    process.exit(0);
}
inspect();
