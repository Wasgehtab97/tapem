// src/server/firebase/admin.ts
import 'server-only';

import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth as _getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore as _getFirestore, type Firestore } from 'firebase-admin/firestore';

const ADMIN_APP_NAME = 'tapem-admin-sdk';
const GLOBAL_STATE_KEY = '__tapem_firebase_admin__';

export class FirebaseAdminConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FirebaseAdminConfigError';
  }
}

export type FirebaseAdminConfigSource = 'b64' | 'trio';

type ServiceAccountConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
  source: FirebaseAdminConfigSource;
};

type FirebaseAdminGlobalState = {
  app: App | null;
  config: ServiceAccountConfig | null;
};

type GlobalWithFirebaseAdmin = typeof globalThis & {
  [GLOBAL_STATE_KEY]?: FirebaseAdminGlobalState;
};

const globalWithFirebaseAdmin = globalThis as GlobalWithFirebaseAdmin;
const globalState =
  globalWithFirebaseAdmin[GLOBAL_STATE_KEY] ?? ({ app: null, config: null } satisfies FirebaseAdminGlobalState);

globalWithFirebaseAdmin[GLOBAL_STATE_KEY] = globalState;

let cachedApp: App | null = globalState.app;
let cachedConfig: ServiceAccountConfig | null = globalState.config;

function setCachedApp(app: App) {
  cachedApp = app;
  globalState.app = app;
}

function setCachedConfig(config: ServiceAccountConfig) {
  cachedConfig = config;
  globalState.config = config;
}

function logDebug(...args: unknown[]) {
  if (process.env.TAPEM_DEBUG && process.env.TAPEM_DEBUG !== '0') {
    // eslint-disable-next-line no-console
    console.log('[firebase-admin]', ...args);
  }
}

function normalizePrivateKey(value: string): string {
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

    return { projectId, clientEmail, privateKey, source: 'b64' };
  } catch (error) {
    if (error instanceof FirebaseAdminConfigError) {
      throw error;
    }
    throw new FirebaseAdminConfigError(
      'FIREBASE_SERVICE_ACCOUNT konnte nicht Base64-dekodiert oder als JSON geparst werden.'
    );
  }
}

function readServiceAccountConfig(): ServiceAccountConfig {
  if (cachedConfig) {
    return cachedConfig;
  }

  const encoded = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
  if (encoded) {
    const config = parseB64ServiceAccount(encoded);
    setCachedConfig(config);
    logDebug('Service Account via Base64 geladen (Projekt:', config.projectId, ')');
    return config;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
  const privateKeyRaw = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKeyRaw) {
    const config: ServiceAccountConfig = {
      projectId,
      clientEmail,
      privateKey: normalizePrivateKey(privateKeyRaw),
      source: 'trio',
    };
    setCachedConfig(config);
    logDebug('Service Account via Trio geladen (Projekt:', config.projectId, ')');
    return config;
  }

  throw new FirebaseAdminConfigError(
    'Firebase Admin SDK nicht konfiguriert. Setze FIREBASE_SERVICE_ACCOUNT (Base64) ODER FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.'
  );
}

function ensureAdminApp(): App {
  if (cachedApp) {
    return cachedApp;
  }

  const existing = getApps().find((app) => app.name === ADMIN_APP_NAME);
  if (existing) {
    setCachedApp(existing);
    if (!cachedConfig) {
      try {
        const config = readServiceAccountConfig();
        setCachedConfig(config);
      } catch (error) {
        logDebug('Admin App wiederverwendet, aber Konfiguration konnte nicht erneut gelesen werden:', error);
      }
    }
    return existing;
  }

  const { projectId, clientEmail, privateKey } = readServiceAccountConfig();

  const app = initializeApp(
    {
      credential: cert({ projectId, clientEmail, privateKey }),
    },
    ADMIN_APP_NAME
  );

  setCachedApp(app);
  logDebug('Admin SDK initialisiert als', ADMIN_APP_NAME, '(Projekt:', projectId, ')');
  return app;
}

export function getFirebaseAdminApp(): App {
  return ensureAdminApp();
}

export function getFirebaseAdminAuth(): Auth {
  return _getAuth(ensureAdminApp());
}

export function getFirebaseAdminFirestore(): Firestore {
  return _getFirestore(ensureAdminApp());
}

export function assertFirebaseAdminReady(): void {
  try {
    ensureAdminApp();
  } catch (error) {
    throw error instanceof Error
      ? error
      : new FirebaseAdminConfigError('Unbekannter Fehler beim Initialisieren des Admin SDK.');
  }
}

export function getFirebaseAdminConfigSummary():
  | { projectId: string; mode: FirebaseAdminConfigSource }
  | null {
  if (cachedConfig) {
    return { projectId: cachedConfig.projectId, mode: cachedConfig.source };
  }
  return null;
}
