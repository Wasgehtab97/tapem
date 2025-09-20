// src/server/firebase/admin.ts
import 'server-only';

import { applicationDefault, cert, getApps, initializeApp, type App, type Credential } from 'firebase-admin/app';
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

export type FirebaseAdminMode = 'production' | 'emulator';

export type FirebaseAdminConfigSummary = {
  projectId: string;
  mode: FirebaseAdminMode;
  usesServiceAccount: boolean;
};

type EmulatorConfig = {
  firestoreHost: string;
  authHost: string;
};

type ServiceAccountConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

type FirebaseAdminGlobalState = {
  app: App | null;
  summary: FirebaseAdminConfigSummary | null;
  auth: Auth | null;
  firestore: Firestore | null;
  emulatorConfigured: boolean;
  emulatorConfig: EmulatorConfig | null;
};

type GlobalWithFirebaseAdmin = typeof globalThis & {
  [GLOBAL_STATE_KEY]?: FirebaseAdminGlobalState;
};

const globalWithFirebaseAdmin = globalThis as GlobalWithFirebaseAdmin;
const defaultState: FirebaseAdminGlobalState = {
  app: null,
  summary: null,
  auth: null,
  firestore: null,
  emulatorConfigured: false,
  emulatorConfig: null,
};

const state = (globalWithFirebaseAdmin[GLOBAL_STATE_KEY] ?? defaultState) as FirebaseAdminGlobalState;
globalWithFirebaseAdmin[GLOBAL_STATE_KEY] = state;

function logDebug(...args: unknown[]) {
  if (process.env.TAPEM_DEBUG && process.env.TAPEM_DEBUG !== '0') {
    // eslint-disable-next-line no-console
    console.log('[firebase-admin]', ...args);
  }
}

function normalizePrivateKey(value: string): string {
  const trimmed = value.trim();
  const unquoted =
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
      ? trimmed.slice(1, -1)
      : trimmed;
  return unquoted.replace(/\\n/g, '\n');
}

function parseBoolean(value: string | undefined): boolean {
  if (!value) {
    return false;
  }
  const normalized = value.trim().toLowerCase();
  return ['1', 'true', 'yes', 'on'].includes(normalized);
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
  } catch (error) {
    if (error instanceof FirebaseAdminConfigError) {
      throw error;
    }
    throw new FirebaseAdminConfigError(
      'FIREBASE_SERVICE_ACCOUNT konnte nicht Base64-dekodiert oder als JSON geparst werden.'
    );
  }
}

function readServiceAccountConfig(): ServiceAccountConfig | null {
  const encoded = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
  if (encoded) {
    const config = parseB64ServiceAccount(encoded);
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
    };
    logDebug('Service Account via Trio geladen (Projekt:', config.projectId, ')');
    return config;
  }

  return null;
}

function detectProjectIdCandidate(): string | null {
  const candidates = [
    process.env.FIREBASE_PROJECT_ID,
    process.env.GCLOUD_PROJECT,
    process.env.GOOGLE_CLOUD_PROJECT,
  ];

  for (const candidate of candidates) {
    if (candidate && candidate.trim().length > 0) {
      return candidate.trim();
    }
  }

  const firebaseConfig = process.env.FIREBASE_CONFIG;
  if (firebaseConfig) {
    try {
      const parsed = JSON.parse(firebaseConfig) as { projectId?: string };
      if (parsed.projectId && parsed.projectId.trim().length > 0) {
        return parsed.projectId.trim();
      }
    } catch {
      // ignore malformed FIREBASE_CONFIG values
    }
  }

  return null;
}

function resolveCredential(): { credential: Credential; projectId: string; usesServiceAccount: boolean } {
  const serviceAccount = readServiceAccountConfig();
  if (serviceAccount) {
    const { projectId, clientEmail, privateKey } = serviceAccount;
    return {
      credential: cert({ projectId, clientEmail, privateKey }),
      projectId,
      usesServiceAccount: true,
    };
  }

  const credential = applicationDefault();
  const projectId = detectProjectIdCandidate();
  if (!projectId) {
    throw new FirebaseAdminConfigError(
      'FIREBASE_PROJECT_ID oder eine gültige Google Application Default Credentials Konfiguration wird benötigt.'
    );
  }

  logDebug('Application Default Credentials verwendet (Projekt:', projectId, ')');
  return { credential, projectId, usesServiceAccount: false };
}

function resolveEmulatorConfig(): EmulatorConfig | null {
  if (!parseBoolean(process.env.USE_FIREBASE_EMULATOR)) {
    return null;
  }

  const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST?.trim();
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST?.trim();

  if (!firestoreHost || !authHost) {
    throw new FirebaseAdminConfigError(
      'USE_FIREBASE_EMULATOR=true erfordert FIRESTORE_EMULATOR_HOST und FIREBASE_AUTH_EMULATOR_HOST.'
    );
  }

  return { firestoreHost, authHost };
}

function ensureAdminApp(): App {
  if (state.app) {
    return state.app;
  }

  const existing = getApps().find((app) => app.name === ADMIN_APP_NAME);
  if (existing) {
    state.app = existing;
    if (!state.summary) {
      const projectId = existing.options.projectId ?? detectProjectIdCandidate() ?? 'unknown';
      const emulatorConfig = resolveEmulatorConfig();
      state.emulatorConfig = emulatorConfig;
      state.summary = {
        projectId,
        mode: emulatorConfig ? 'emulator' : 'production',
        usesServiceAccount: Boolean(readServiceAccountConfig()),
      };
    }
    return existing;
  }

  const { credential, projectId, usesServiceAccount } = resolveCredential();
  const emulatorConfig = resolveEmulatorConfig();

  const app = initializeApp(
    {
      credential,
      projectId,
    },
    ADMIN_APP_NAME
  );

  state.app = app;
  state.summary = {
    projectId,
    mode: emulatorConfig ? 'emulator' : 'production',
    usesServiceAccount,
  };
  state.emulatorConfig = emulatorConfig;

  logDebug('Admin SDK initialisiert als', ADMIN_APP_NAME, '(Projekt:', projectId, ')');
  return app;
}

function ensureServices(): { app: App; auth: Auth; firestore: Firestore } {
  const app = ensureAdminApp();

  if (!state.auth) {
    state.auth = _getAuth(app);
  }

  if (!state.firestore) {
    state.firestore = _getFirestore(app);
  }

  const emulatorConfig = state.emulatorConfig;
  if (emulatorConfig && !state.emulatorConfigured && state.auth && state.firestore) {
    logDebug('Verbinde Firebase Admin SDK mit Emulatoren', emulatorConfig);
    state.firestore.settings({ host: emulatorConfig.firestoreHost, ssl: false });
    const authHost = emulatorConfig.authHost.startsWith('http')
      ? emulatorConfig.authHost
      : `http://${emulatorConfig.authHost}`;
    state.auth.useEmulator(authHost);
    state.emulatorConfigured = true;
  }

  if (!state.summary) {
    const projectId = app.options.projectId ?? detectProjectIdCandidate() ?? 'unknown';
    state.summary = {
      projectId,
      mode: emulatorConfig ? 'emulator' : 'production',
      usesServiceAccount: Boolean(readServiceAccountConfig()),
    };
  }

  return { app, auth: state.auth!, firestore: state.firestore! };
}

export function getFirebaseAdminApp(): App {
  return ensureServices().app;
}

export function getFirebaseAdminAuth(): Auth {
  return ensureServices().auth;
}

export function getFirebaseAdminFirestore(): Firestore {
  return ensureServices().firestore;
}

export function assertFirebaseAdminReady(): void {
  try {
    ensureServices();
  } catch (error) {
    throw error instanceof Error
      ? error
      : new FirebaseAdminConfigError('Unbekannter Fehler beim Initialisieren des Admin SDK.');
  }
}

export function getFirebaseAdminConfigSummary(): FirebaseAdminConfigSummary | null {
  if (state.summary) {
    return state.summary;
  }
  return null;
}
