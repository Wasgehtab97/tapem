'use client';

/**
 * Firebase Web SDK bootstrap for client-side use in Next.js.
 * - Reads NEXT_PUBLIC_* envs safely and validates required keys
 * - Initializes exactly one Firebase App (HMR-safe)
 * - Provides singleton Auth (with local persistence) and Firestore instances
 * - Optional Emulator wiring via NEXT_PUBLIC_USE_FIREBASE_EMULATOR + host envs
 * - Helpful debug logs when NEXT_PUBLIC_TAPEM_DEBUG=1
 */

import { initializeApp, getApps, type FirebaseApp, type FirebaseOptions } from 'firebase/app';
import {
  browserLocalPersistence,
  getAuth,
  setPersistence,
  connectAuthEmulator,
  type Auth,
} from 'firebase/auth';
import {
  getFirestore,
  connectFirestoreEmulator,
  type Firestore,
} from 'firebase/firestore';

/* ---------------------------------- Env ---------------------------------- */

const REQUIRED_ENV_KEYS = [
  'NEXT_PUBLIC_FIREBASE_API_KEY',
  'NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN',
  'NEXT_PUBLIC_FIREBASE_PROJECT_ID',
  'NEXT_PUBLIC_FIREBASE_APP_ID',
  // Keep these as required since the project uses Storage/Messaging in places.
  'NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET',
  'NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID',
] as const;

type RequiredEnvKey = (typeof REQUIRED_ENV_KEYS)[number];

function readEnv(key: string): string | undefined {
  // In the browser, Next.js inlines NEXT_PUBLIC_* at build time.
  const v = (process.env as Record<string, string | undefined>)[key];
  return typeof v === 'string' && v.trim() ? v : undefined;
}

const DEBUG = readEnv('NEXT_PUBLIC_TAPEM_DEBUG') === '1';

function dbg(...args: any[]) {
  if (DEBUG) console.log('[firebase:client]', ...args);
}

export class FirebaseClientConfigError extends Error {
  constructor(public missingKeys: RequiredEnvKey[]) {
    super(`Firebase client configuration is incomplete (missing: ${missingKeys.join(', ')})`);
    this.name = 'FirebaseClientConfigError';
  }
}

function resolveClientConfig(): FirebaseOptions {
  const missing: RequiredEnvKey[] = [];
  const get = (k: RequiredEnvKey) => {
    const v = readEnv(k);
    if (!v) missing.push(k);
    return v;
  };

  const projectId = get('NEXT_PUBLIC_FIREBASE_PROJECT_ID');
  // Prefer explicit bucket; otherwise derive from projectId.
  const storageBucket =
    readEnv('NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET') ??
    (projectId ? `${projectId}.appspot.com` : undefined);

  const cfg: FirebaseOptions = {
    apiKey: get('NEXT_PUBLIC_FIREBASE_API_KEY'),
    authDomain: get('NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN'),
    projectId: projectId,
    appId: get('NEXT_PUBLIC_FIREBASE_APP_ID'),
    storageBucket,
    messagingSenderId: get('NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID'),
    measurementId: readEnv('NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID'), // optional
  };

  if (missing.length) throw new FirebaseClientConfigError(missing);
  return cfg;
}

/* ------------------------------ Emulator opts ----------------------------- */

const USE_EMULATORS = readEnv('NEXT_PUBLIC_USE_FIREBASE_EMULATOR') === 'true';
const AUTH_EMULATOR = readEnv('NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST') ?? 'localhost:9099';
const FS_EMULATOR = readEnv('NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST') ?? 'localhost:8080';

/* --------------------------- HMR-safe singletons -------------------------- */

declare global {
  interface Window {
    __TAPEM_FB__?: {
      app?: FirebaseApp;
      auth?: Auth;
      db?: Firestore;
      emulatorsLinked?: boolean;
    };
  }
}

const globalCache = ((): NonNullable<Window['__TAPEM_FB__']> => {
  if (typeof window === 'undefined') return {};
  window.__TAPEM_FB__ ||= {};
  return window.__TAPEM_FB__;
})();

function ensureBrowser() {
  if (typeof window === 'undefined') {
    // This file is "use client", but guard anyway to avoid accidental SSR import usage.
    throw new Error('Firebase client SDK may only be used in the browser.');
  }
}

/* ------------------------------- API exports ------------------------------ */

export function getFirebaseApp(): FirebaseApp {
  ensureBrowser();

  if (globalCache.app) return globalCache.app;

  const existing = getApps()[0];
  if (existing) {
    globalCache.app = existing;
    dbg('reusing existing app');
    return existing;
  }

  const config = resolveClientConfig();
  dbg('initializing app for project', config.projectId, { useEmulators: USE_EMULATORS });
  const app = initializeApp(config);
  globalCache.app = app;
  return app;
}

let authInitPromise: Promise<Auth> | null = null;

export async function getFirebaseAuth(): Promise<Auth> {
  ensureBrowser();
  if (globalCache.auth) return globalCache.auth;
  if (!authInitPromise) {
    authInitPromise = (async () => {
      const app = getFirebaseApp();
      const auth = getAuth(app);

      // Persistence first, then optional emulator wiring.
      try {
        await setPersistence(auth, browserLocalPersistence);
      } catch (err) {
        console.warn('[firebase] failed to set local persistence; continuing with default', err);
      }

      if (USE_EMULATORS && !globalCache.emulatorsLinked) {
        try {
          const url = AUTH_EMULATOR.startsWith('http') ? AUTH_EMULATOR : `http://${AUTH_EMULATOR}`;
          connectAuthEmulator(auth, url, { disableWarnings: true });
          dbg('Auth emulator connected at', url);
        } catch (e) {
          console.warn('[firebase] failed to connect Auth emulator', e);
        }
      }

      globalCache.auth = auth;
      return auth;
    })();
  }
  return authInitPromise;
}

export function getFirebaseFirestore(): Firestore {
  ensureBrowser();
  if (globalCache.db) return globalCache.db;

  const db = getFirestore(getFirebaseApp());

  if (USE_EMULATORS && !globalCache.emulatorsLinked) {
    try {
      const [host, portStr] = FS_EMULATOR.split(':');
      const port = Number(portStr || 8080);
      connectFirestoreEmulator(db, host, port);
      dbg('Firestore emulator connected at', `${host}:${port}`);
    } catch (e) {
      console.warn('[firebase] failed to connect Firestore emulator', e);
    }
  }

  globalCache.db = db;
  globalCache.emulatorsLinked = true;
  return db;
}

export function isFirebaseClientConfigured(): boolean {
  try {
    resolveClientConfig();
    return true;
  } catch (e) {
    if (e instanceof FirebaseClientConfigError) {
      console.warn('[firebase] client configuration missing keys', e.missingKeys);
      return false;
    }
    throw e;
  }
}
