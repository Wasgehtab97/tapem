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

type ServiceAccountConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

function normalizePrivateKey(value: string): string {
  return value.replace(/\r?\n/g, '\n');
}

function parseServiceAccountJson(encoded: string): ServiceAccountConfig {
  try {
    const json = Buffer.from(encoded, 'base64').toString('utf8');
    const parsed = JSON.parse(json) as {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };

    const projectId = parsed.project_id?.trim();
    const clientEmail = parsed.client_email?.trim();
    const privateKey = parsed.private_key;

    if (!projectId || !clientEmail || !privateKey) {
      throw new FirebaseAdminConfigError(
        'FIREBASE_SERVICE_ACCOUNT is missing required fields (project_id, client_email, private_key).'
      );
    }

    return {
      projectId,
      clientEmail,
      privateKey: normalizePrivateKey(privateKey),
    };
  } catch (error) {
    if (error instanceof FirebaseAdminConfigError) {
      throw error;
    }

    throw new FirebaseAdminConfigError('FIREBASE_SERVICE_ACCOUNT could not be parsed.');
  }
}

function readServiceAccountConfig(): ServiceAccountConfig {
  const encoded = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (encoded && encoded.trim().length > 0) {
    return parseServiceAccountJson(encoded.trim());
  }

  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKey) {
    return {
      projectId,
      clientEmail,
      privateKey: normalizePrivateKey(privateKey),
    };
  }

  throw new FirebaseAdminConfigError(
    'Firebase Admin SDK configuration is missing. Set FIREBASE_SERVICE_ACCOUNT (Base64) or FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.'
  );
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

  const { projectId, clientEmail, privateKey } = readServiceAccountConfig();

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
