#!/usr/bin/env node

// scripts/migrate_gym_codes.js
// Simple Node.js script to migrate gym codes without Flutter dependencies

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Load service account from firebase.json to determine which project
const firebaseJson = JSON.parse(fs.readFileSync(path.join(__dirname, '../firebase.json'), 'utf8'));
const projectId = firebaseJson.projects?.default || 'tap-em-dev';

console.log(`🚀 Starting Gym Code Migration for ${projectId}...\n`);

// Initialize Firebase Admin
admin.initializeApp({
    projectId: projectId
});

const db = admin.firestore();

// Generate readable 6-character code
function generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

// Check if code exists
async function codeExists(code) {
    const snapshot = await db.collectionGroup('codes')
        .where('code', '==', code)
        .limit(1)
        .get();
    return !snapshot.empty;
}

// Generate unique code
async function generateUniqueCode(maxAttempts = 10) {
    for (let i = 0; i < maxAttempts; i++) {
        const code = generateCode();
        const exists = await codeExists(code);
        if (!exists) {
            return code;
        }
    }
    throw new Error(`Failed to generate unique code after ${maxAttempts} attempts`);
}

async function migrate() {
    try {
        // Get all gyms
        console.log('📋 Fetching all gyms...');
        const gymsSnapshot = await db.collection('gyms').get();
        console.log(`Found ${gymsSnapshot.size} gyms\n`);

        let successCount = 0;
        let skipCount = 0;
        let errorCount = 0;

        for (const gymDoc of gymsSnapshot.docs) {
            const gymId = gymDoc.id;
            const gymData = gymDoc.data();
            const gymName = gymData.name || 'Unknown';
            const oldCode = gymData.code;

            console.log(`Processing: ${gymName} (${gymId})`);

            // Check if gym already has rotating codes
            const existingCodeSnapshot = await db
                .collection('gym_codes')
                .doc(gymId)
                .collection('codes')
                .where('isActive', '==', true)
                .where('expiresAt', '>', admin.firestore.Timestamp.now())
                .limit(1)
                .get();

            if (!existingCodeSnapshot.empty) {
                const existingCode = existingCodeSnapshot.docs[0].data();
                console.log(`  ⏭️  Already has rotating code: ${existingCode.code}`);
                console.log(`  Expires: ${existingCode.expiresAt.toDate().toISOString()}`);
                skipCount++;
                console.log('');
                continue;
            }

            try {
                // Generate unique code
                const newCode = await generateUniqueCode();

                // Calculate expiration (30 days from now)
                const now = new Date();
                const expiresAt = new Date(now);
                expiresAt.setDate(expiresAt.getDate() + 30);

                // Create code document
                await db
                    .collection('gym_codes')
                    .doc(gymId)
                    .collection('codes')
                    .add({
                        code: newCode,
                        gymId: gymId,
                        createdAt: admin.firestore.Timestamp.now(),
                        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                        isActive: true,
                        createdBy: 'migration-script'
                    });

                console.log(`  ✅ Created rotating code: ${newCode}`);
                console.log(`  Expires: ${expiresAt.toISOString()}`);

                if (oldCode) {
                    console.log(`  Old static code was: ${oldCode}`);
                }

                successCount++;
            } catch (error) {
                console.error(`  ❌ Error: ${error.message}`);
                errorCount++;
            }

            console.log('');
        }

        // Summary
        console.log('━'.repeat(50));
        console.log('Migration Complete!\n');
        console.log(`✅ Successfully migrated: ${successCount} gyms`);
        console.log(`⏭️  Skipped (already migrated): ${skipCount} gyms`);
        if (errorCount > 0) {
            console.log(`❌ Errors: ${errorCount} gyms`);
        }
        console.log('━'.repeat(50));

        process.exit(0);
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    }
}

migrate();
