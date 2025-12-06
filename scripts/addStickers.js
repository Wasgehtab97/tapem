const admin = require('firebase-admin');

// Initialize Firebase Admin with application default credentials
// This will use the credentials from `firebase login`
admin.initializeApp({
    projectId: 'tap-em-dev'
});

const db = admin.firestore();

// Default stickers to add
const defaultStickers = [
    {
        id: 'sticker_1',
        name: 'Thumbs Up',
        imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44d/512.gif',
        isPremium: false,
        sortOrder: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
        id: 'sticker_2',
        name: 'Heart',
        imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/2764_fe0f/512.gif',
        isPremium: false,
        sortOrder: 2,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
        id: 'sticker_3',
        name: 'Fire',
        imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif',
        isPremium: false,
        sortOrder: 3,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
        id: 'sticker_4',
        name: 'Muscle',
        imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4aa/512.gif',
        isPremium: false,
        sortOrder: 4,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
        id: 'sticker_5',
        name: '100',
        imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4af/512.gif',
        isPremium: false,
        sortOrder: 5,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
        id: 'sticker_6',
        name: 'Party',
        imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif',
        isPremium: false,
        sortOrder: 6,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    }
];

async function addStickers() {
    console.log('Adding default stickers...');

    const batch = db.batch();

    for (const sticker of defaultStickers) {
        const { id, ...data } = sticker;
        const ref = db.collection('stickers').doc(id);
        batch.set(ref, data);
    }

    await batch.commit();
    console.log(`✅ Added ${defaultStickers.length} stickers successfully!`);
    process.exit(0);
}

addStickers().catch(error => {
    console.error('Error adding stickers:', error);
    process.exit(1);
});
