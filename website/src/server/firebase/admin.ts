import 'server-only';

import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth as getAdminAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore as getAdminFirestore, type Firestore } from 'firebase-admin/firestore';

const ADMIN_APP_NAME = 'tapem-admin-sdk';

export class FirebaseAdminConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FirebaseAdminConfigError';
  }
}

let cachedAdminApp: App | null = null;

function getRequiredEnv(key: 'FIREBASE_PROJECT_ID' | 'FIREBASE_CLIENT_EMAIL' | 'FIREBASE_PRIVATE_KEY'): string {
  const value = process.env[key];
  if (!value || value.length === 0) {
    throw new FirebaseAdminConfigError(`Missing required server environment variable: ${key}`);
  }
  return value;
}

function initializeAdminApp(): App {
  if (cachedAdminApp) {
    return cachedAdminApp;
  }

  const existingApp = getApps().find((app) => app.name === ADMIN_APP_NAME);
  if (existingApp) {
    cachedAdminApp = existingApp;
    return cachedAdminApp;
  }

  const projectId = getRequiredEnv('FIREBASE_PROJECT_ID');
  const clientEmail = getRequiredEnv('FIREBASE_CLIENT_EMAIL');
  const privateKey = getRequiredEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n');

  cachedAdminApp = initializeApp(
    {
      credential: cert({ projectId, clientEmail, privateKey }),
    },
    ADMIN_APP_NAME,
  );

  return cachedAdminApp;
}

export function getFirebaseAdminApp(): App {
  return initializeAdminApp();
}

export function getFirebaseAdminAuth(): Auth {
  return getAdminAuth(initializeAdminApp());
}

export function getFirebaseAdminFirestore(): Firestore {
  return getAdminFirestore(initializeAdminApp());
}
