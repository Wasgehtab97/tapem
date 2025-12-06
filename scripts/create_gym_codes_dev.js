#!/usr/bin/env node

// scripts/create_gym_codes_dev.js
// Creates rotating gym codes for DEV environment using Firestore REST API

const https = require('https');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

console.log('🚀 Creating Gym Codes for DEV environment...\n');

const PROJECT_ID = 'tap-em-dev';

// Generate readable 6-character code
function generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

async function getAccessToken() {
    try {
        const { stdout } = await execPromise('firebase login:ci --no-localhost');
        return stdout.trim();
    } catch (error) {
        // Try to get token from gcloud
        const { stdout } = await execPromise('gcloud auth print-access-token');
        return stdout.trim();
    }
}

async function createCodeManually(gymId, gymName) {
    const code = generateCode();
    const now = new Date();
    const expiresAt = new Date(now);
    expiresAt.setDate(expiresAt.getDate() + 30);

    console.log(`\n📋 Manual Code Creation for: ${gymName} (${gymId})`);
    console.log('━'.repeat(50));
    console.log(`Generated Code: ${code}`);
    console.log(`Expires: ${expiresAt.toISOString()}`);
    console.log('');
    console.log('📝 Add this to Firebase Console:');
    console.log(`https://console.firebase.google.com/project/${PROJECT_ID}/firestore/data/~2Fgym_codes~2F${gymId}~2Fcodes`);
    console.log('');
    console.log('Fields to add:');
    console.log(JSON.stringify({
        code: code,
        gymId: gymId,
        createdAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        isActive: true,
        createdBy: 'manual-script-dev'
    }, null, 2));
    console.log('━'.repeat(50));
}

async function main() {
    const devGyms = [
        { id: 'Lifthouse_dev', name: 'Lifthouse Dev' },
        { id: 'Stahlwerk_dev', name: 'Stahlwerk Dev' }
    ];

    console.log('⚠️  This script will generate codes for you to add manually.');
    console.log('   (Automatic creation requires service account credentials)\n');

    for (const gym of devGyms) {
        await createCodeManually(gym.id, gym.name);
    }

    console.log('\n✅ Code generation complete!');
    console.log('📋 Copy the codes above and add them to Firebase Console.');
}

main().catch(console.error);
