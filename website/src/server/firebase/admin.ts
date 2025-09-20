// src/server/firebase/admin.ts
import 'server-only';

import { cert, getApp, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth as _getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore as _getFirestore, type Firestore } from 'firebase-admin/firestore';

const ADMIN_APP_NAME = 'tapem-admin-sdk';

export class FirebaseAdminConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FirebaseAdminConfigError';
  }
}

type ServiceAccountConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

function logDebug(...args: any[]) {
  // Setze TAPEM_DEBUG=1 in .env.local, wenn du die Logs sehen willst
  if (process.env.TAPEM_DEBUG && process.env.TAPEM_DEBUG !== '0') {
    // eslint-disable-next-line no-console
    console.log('[firebase-admin]', ...args);
  }
}

function normalizePrivateKey(value: string): string {
  // erlaubt sowohl echte Zeilenumbrüche als auch escaped "\n"
  return value.replace(/\\n/g, '\n').replace(/\r?\n/g, '\n').trim();
}

function parseB64ServiceAccount(encoded: string): ServiceAccountConfig {
  try {
    const json = Buffer.from(encoded, 'base64').toString('utf8');
    const parsed = JSON.parse(json) as {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };

    const projectId = parsed.project_id?.trim();
    const clientEmail = parsed.client_email?.trim();
    const privateKey = parsed.private_key ? normalizePrivateKey(parsed.private_key) : undefined;

    if (!projectId || !clientEmail || !privateKey) {
      throw new FirebaseAdminConfigError(
        'FIREBASE_SERVICE_ACCOUNT fehlt Pflichtfelder: project_id, client_email, private_key.'
      );
    }

    return { projectId, clientEmail, privateKey };
  } catch (e) {
    if (e instanceof FirebaseAdminConfigError) throw e;
    throw new FirebaseAdminConfigError(
      'FIREBASE_SERVICE_ACCOUNT konnte nicht Base64-decodiert/geparst werden.'
    );
  }
}

function readServiceAccountConfig(): ServiceAccountConfig {
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
  if (b64) {
    const cfg = parseB64ServiceAccount(b64);
    logDebug('SA (base64) ok; project:', cfg.projectId);
    return cfg;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
  const privateKeyRaw = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKeyRaw) {
    const privateKey = normalizePrivateKey(privateKeyRaw);
    logDebug('SA (trio) ok; project:', projectId);
    return { projectId, clientEmail, privateKey };
  }

  throw new FirebaseAdminConfigError(
    'Firebase Admin SDK nicht konfiguriert. Setze FIREBASE_SERVICE_ACCOUNT (Base64) ODER FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.'
  );
}

let cachedApp: App | null = null;

function ensureAdminApp(): App {
  if (cachedApp) return cachedApp;

  // Falls bereits initialisiert (Hot Reload in dev), wiederverwenden
  const existing = getApps().find((a) => a.name === ADMIN_APP_NAME);
  if (existing) {
    cachedApp = existing;
    return cachedApp;
  }

  const { projectId, clientEmail, privateKey } = readServiceAccountConfig();

  cachedApp = initializeApp(
    {
      credential: cert({ projectId, clientEmail, privateKey }),
    },
    ADMIN_APP_NAME
  );

  logDebug('Admin SDK initialisiert als', ADMIN_APP_NAME);
  return cachedApp;
}

/** Hole (oder initialisiere) die Admin-App. */
export function getFirebaseAdminApp(): App {
  return ensureAdminApp();
}

/** Firebase Admin Auth – nur serverseitig verwenden. */
export function getFirebaseAdminAuth(): Auth {
  return _getAuth(ensureAdminApp());
}

/** Firebase Admin Firestore – nur serverseitig verwenden. */
export function getFirebaseAdminFirestore(): Firestore {
  return _getFirestore(ensureAdminApp());
}

/** Optional: schneller „Gesundheitscheck“ für deine API-Routen/Guards. */
export function assertFirebaseAdminReady(): void {
  try {
    ensureAdminApp();
  } catch (e) {
    // Fehler transparent weiterreichen – deine API kann die Message als 500 zurückgeben.
    throw e instanceof Error
      ? e
      : new FirebaseAdminConfigError('Unbekannter Fehler beim Initialisieren des Admin SDK.');
  }
}
