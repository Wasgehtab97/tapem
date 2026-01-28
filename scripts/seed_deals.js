// scripts/seed_deals.js
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

async function seedDeals() {
    console.log('🧹 Cleaning old deals...');
    const snapshot = await db.collection('deals').get();
    const batch = db.batch();
    snapshot.forEach(doc => {
        batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('✅ Old deals cleared.');

    console.log('🌱 Seeding fresh Deals...');
    const deals = [
        {
            title: 'ESN: Maximale Performance',
            description: 'Hol dir die besten Supplements von ESN. Mit dem Code TAPEM erhältst du den maximalen Rabatt auf Designer Whey, Creatine und mehr. Supporte uns bei jedem Einkauf!',
            partnerName: 'ESN',
            partnerLogoUrl: 'https://www.esn.com/cdn/shop/files/ESN_Logo_Black_Small.png',
            imageUrl: 'https://images.unsplash.com/photo-1593079831268-3381b0db4a77?w=1200&q=80', // Premium gym/supplement shot
            code: 'TAPEM',
            link: 'https://www.esn.com?ref=tapem',
            category: 'Supplements',
            isActive: true,
            priority: 1,
            clickCount: 0,
            createdAt: admin.firestore.Timestamp.now(),
        },
        {
            title: 'More Nutrition: 20% Rabatt',
            description: 'Sicher dir 20% Rabatt auf deine nächste Bestellung bei More Nutrition mit dem Code TAPEM. Nutze den Code für maximalen Rabatt auf Proteine, Chunky Flavour und mehr. Ideal für dein Ziel!',
            partnerName: 'More Nutrition',
            partnerLogoUrl: 'https://images.ctfassets.net/7st994939fde/1S2v3q1Q9i0q4o4kG2q4OQ/9f2b8e8f8b8c8b8c8b8c8b8c8b8c8b8c/more-nutrition-logo.png',
            imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=1200&q=80', // Robust meal prep shot
            code: 'TAPEM',
            link: 'https://more-nutrition.de?ref=tapem',
            category: 'Supplements',
            isActive: true,
            priority: 2,
            clickCount: 0,
            createdAt: admin.firestore.Timestamp.now(),
        },
        {
            title: 'OACE: Premium Gymwear',
            description: 'Entdecke die exklusive Gymwear von OACE. Mit dem Code TAPEM erhältst du exklusive Rabatte auf die neuesten Kollektionen. Style trifft Performance – hol dir deinen Look!',
            partnerName: 'OACE',
            partnerLogoUrl: 'https://oace.de/cdn/shop/files/OACE_LOGO_BLACK.png',
            imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1200&q=80', // Fashion/Apparel shot
            code: 'TAPEM',
            link: 'https://oace.de?ref=tapem',
            category: 'Clothing',
            isActive: true,
            priority: 3,
            clickCount: 0,
            createdAt: admin.firestore.Timestamp.now(),
        },
    ];

    const finalBatch = db.batch();
    for (const deal of deals) {
        const docRef = db.collection('deals').doc();
        finalBatch.set(docRef, deal);
        console.log(`➕ Added: ${deal.partnerName} (${deal.code})`);
    }

    try {
        await finalBatch.commit();
        console.log('🚀 Seeding completed successfully.');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error seeding deals:', err);
        process.exit(1);
    }
}
seedDeals();
