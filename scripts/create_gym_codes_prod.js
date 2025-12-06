#!/usr/bin/env node

// scripts/create_gym_codes_prod.js
// Creates rotating gym codes for PRODUCTION environment

console.log('🚀 Creating Gym Codes for PRODUCTION environment...\n');

const PROJECT_ID = 'tap-em';

// Generate readable 6-character code
function generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

function createCodeManually(gymId, gymName) {
    const code = generateCode();
    const now = new Date();
    const expiresAt = new Date(now);
    expiresAt.setDate(expiresAt.getDate() + 30);

    console.log(`\n📋 ${gymName} (${gymId})`);
    console.log('━'.repeat(50));
    console.log(`Code: ${code}`);
    console.log(`Expires: ${expiresAt.toISOString()}`);
    console.log('');
    console.log('Add to: https://console.firebase.google.com/project/' + PROJECT_ID + '/firestore/data/~2Fgym_codes~2F' + gymId + '~2Fcodes');
    console.log('');
    console.log('Fields:');
    console.log(JSON.stringify({
        code: code,
        gymId: gymId,
        createdAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        isActive: true,
        createdBy: 'auto-script-prod'
    }, null, 2));
    console.log('━'.repeat(50));

    return { gymId, gymName, code, expiresAt: expiresAt.toISOString() };
}

async function main() {
    // Production gyms based on Firebase screenshot
    const prodGyms = [
        { id: 'unigym_essen', name: 'Unigym Essen' },
        { id: 'bodypower_weissenthurm', name: 'Bodypower Weissenthurm' },
        { id: 'club_aktiv', name: 'Club Aktiv' },
        { id: 'fitnessfirst_myzeil', name: 'FitnessFirst MyZeil' },
        { id: 'gym_01', name: 'Gym 01' },
        { id: 'gym_frankfurt', name: 'Gym Frankfurt' },
        { id: 'lifthouse_koblenz', name: 'Lifthouse Koblenz' },
        { id: 'mcfit_baelau', name: 'McFit Bälau' },
        { id: 'medifitness_ruesselsheim', name: 'Medifitness Rüsselsheim' },
        { id: 'testgym_a', name: 'TestGym A' },
        { id: 'testgym_ml', name: 'TestGym ML' }
    ];

    console.log('⚠️  This script generates codes for manual Firebase Console entry.');
    console.log('   (Automatic creation requires service account credentials)\n');
    console.log(`📊 Generating codes for ${prodGyms.length} gyms...\n`);

    const allCodes = [];

    for (const gym of prodGyms) {
        const result = createCodeManually(gym.id, gym.name);
        allCodes.push(result);
    }

    // Summary table
    console.log('\n\n━'.repeat(50));
    console.log('📊 SUMMARY - ALL CODES');
    console.log('━'.repeat(50));
    console.log('');
    console.log('| Gym | Code | Expires |');
    console.log('|-----|------|---------|');

    allCodes.forEach(({ gymName, code, expiresAt }) => {
        const shortDate = expiresAt.split('T')[0];
        console.log(`| ${gymName} | ${code} | ${shortDate} |`);
    });

    console.log('');
    console.log('━'.repeat(50));
    console.log('✅ Code generation complete!');
    console.log('');
    console.log('📋 Next Steps:');
    console.log('1. Copy codes to password manager');
    console.log('2. Add each code to Firebase Console (links above)');
    console.log('3. Test registration with one code');
    console.log('4. Verify in Firebase Console');
    console.log('');
    console.log('🔗 Firebase Console:');
    console.log(`https://console.firebase.google.com/project/${PROJECT_ID}/firestore/data/~2Fgym_codes`);
    console.log('');
}

main().catch(console.error);
