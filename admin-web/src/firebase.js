import { initializeApp } from 'firebase/app';
import { getAuth, setPersistence, browserLocalPersistence } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc } from 'firebase/firestore';
import { getFunctions, httpsCallable, connectFunctionsEmulator } from 'firebase/functions';
const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
};
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
setPersistence(auth, browserLocalPersistence);
const db = getFirestore(app);
const functions = getFunctions(app, import.meta.env.VITE_FUNCTIONS_REGION);
// Optional: Emulator-Nutzung steuern über Env
if (import.meta.env.VITE_USE_EMULATORS === 'true') {
    connectFirestoreEmulator(db, 'localhost', 8080);
    connectFunctionsEmulator(functions, 'localhost', 5001);
}
// Helper to refresh claims
async function refreshClaims() {
    const current = auth.currentUser;
    if (!current)
        return;
    await current.getIdToken(true);
}
async function ensureUserDoc(uid, email, role) {
    try {
        const ref = doc(db, 'users', uid);
        const snap = await getDoc(ref);
        if (snap.exists())
            return;
        await setDoc(ref, {
            email: email || null,
            role: role || null,
            gymCodes: [],
            createdAt: new Date(),
        }, { merge: true });
    }
    catch (e) {
        console.warn('ensureUserDoc failed', e);
    }
}
// Sample callable wrappers
const listGyms = httpsCallable(functions, 'adminListGyms');
const listUsers = httpsCallable(functions, 'adminListUsers');
export { app, auth, db, functions, listGyms, listUsers, refreshClaims, ensureUserDoc };
