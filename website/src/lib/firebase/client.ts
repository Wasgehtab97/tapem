'use client';

import { getApps, initializeApp, type FirebaseApp, type FirebaseOptions } from 'firebase/app';
import {
  browserLocalPersistence,
  connectAuthEmulator,
  getAuth,
  setPersistence,
  type Auth,
} from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore, type Firestore } from 'firebase/firestore';

const REQUIRED_ENV_KEYS = [
  'NEXT_PUBLIC_FIREBASE_API_KEY',
  'NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN',
  'NEXT_PUBLIC_FIREBASE_PROJECT_ID',
  'NEXT_PUBLIC_FIREBASE_APP_ID',
] as const;

type RequiredEnvKey = (typeof REQUIRED_ENV_KEYS)[number];

function readEnv(key: string): string | undefined {
  const value = (process.env as Record<string, string | undefined>)[key];
  if (typeof value !== 'string') {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function parseBoolean(value: string | undefined): boolean {
  if (!value) {
    return false;
  }
  const normalized = value.trim().toLowerCase();
  return normalized === 'true' || normalized === '1' || normalized === 'yes';
}

const DEBUG = readEnv('NEXT_PUBLIC_TAPEM_DEBUG') === '1';
const log = (...args: unknown[]) => {
  if (DEBUG) {
    console.log('[firebase:client]', ...args);
  }
};

export class FirebaseClientConfigError extends Error {
  constructor(public readonly missing: RequiredEnvKey[]) {
    super(`Firebase client configuration is incomplete (missing: ${missing.join(', ')})`);
    this.name = 'FirebaseClientConfigError';
  }
}

let cachedConfig: FirebaseOptions | null = null;
let cachedConfigError: FirebaseClientConfigError | null = null;
let missingLogged = false;

function resolveConfig(): FirebaseOptions {
  if (cachedConfig) {
    return cachedConfig;
  }
  if (cachedConfigError) {
    throw cachedConfigError;
  }

  const missing: RequiredEnvKey[] = [];
  const requireEnv = (key: RequiredEnvKey) => {
    const value = readEnv(key);
    if (!value) {
      missing.push(key);
    }
    return value;
  };

  const apiKey = requireEnv('NEXT_PUBLIC_FIREBASE_API_KEY');
  const authDomain = requireEnv('NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN');
  const projectId = requireEnv('NEXT_PUBLIC_FIREBASE_PROJECT_ID');
  const appId = requireEnv('NEXT_PUBLIC_FIREBASE_APP_ID');

  if (missing.length > 0 || !apiKey || !authDomain || !projectId || !appId) {
    cachedConfigError = new FirebaseClientConfigError(missing);
    throw cachedConfigError;
  }

  const options: FirebaseOptions = {
    apiKey,
    authDomain,
    projectId,
    appId,
  };

  const storageBucket = readEnv('NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET') ?? `${projectId}.appspot.com`;
  if (storageBucket) {
    options.storageBucket = storageBucket;
  }

  const messagingSenderId = readEnv('NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID');
  if (messagingSenderId) {
    options.messagingSenderId = messagingSenderId;
  }

  const measurementId = readEnv('NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID');
  if (measurementId) {
    options.measurementId = measurementId;
  }

  cachedConfig = options;
  cachedConfigError = null;
  return options;
}

function formatEmulatorUrl(host: string): string {
  if (!host) {
    return 'http://localhost:9099';
  }
  if (host.startsWith('http://') || host.startsWith('https://')) {
    return host;
  }
  return `http://${host}`;
}

function parseHostAndPort(target: string): { host: string; port: number } {
  if (!target) {
    return { host: 'localhost', port: 8080 };
  }
  const [hostPart, portPart] = target.split(':');
  const host = hostPart?.trim() ?? 'localhost';
  const port = Number(portPart) || 8080;
  return { host, port };
}

const EMULATOR_ENABLED = parseBoolean(readEnv('NEXT_PUBLIC_USE_FIREBASE_EMULATOR'));
const AUTH_EMULATOR_HOST = readEnv('NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST') ?? 'localhost:9099';
const FIRESTORE_EMULATOR_HOST = readEnv('NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST') ?? 'localhost:8080';

type FirebaseClientCache = {
  app?: FirebaseApp;
  auth?: Auth;
  firestore?: Firestore;
  emulators: {
    auth?: boolean;
    firestore?: boolean;
  };
};

declare global {
  interface Window {
    __TAPEM_FB__?: FirebaseClientCache;
  }
}

let globalCache: FirebaseClientCache = { emulators: {} };

if (typeof window !== 'undefined') {
  globalCache = window.__TAPEM_FB__ ?? { emulators: {} };
  window.__TAPEM_FB__ = globalCache;
  globalCache.emulators = globalCache.emulators ?? {};
}

function ensureBrowser() {
  if (typeof window === 'undefined') {
    throw new Error('Firebase client SDK may only be used in the browser.');
  }
}

export function getFirebaseApp(): FirebaseApp {
  ensureBrowser();

  if (globalCache.app) {
    return globalCache.app;
  }

  const existing = getApps()[0];
  if (existing) {
    globalCache.app = existing;
    return existing;
  }

  const config = resolveConfig();
  log('init app', config.projectId, { emulator: EMULATOR_ENABLED });
  const app = initializeApp(config);
  globalCache.app = app;
  return app;
}

let authInitPromise: Promise<Auth> | null = null;

export async function getFirebaseAuth(): Promise<Auth> {
  ensureBrowser();

  if (globalCache.auth) {
    return globalCache.auth;
  }

  if (!authInitPromise) {
    authInitPromise = (async () => {
      const auth = getAuth(getFirebaseApp());
      try {
        await setPersistence(auth, browserLocalPersistence);
      } catch (error) {
        console.warn('[firebase] failed to enable persistence', error);
      }

      if (EMULATOR_ENABLED && !globalCache.emulators.auth) {
        const url = formatEmulatorUrl(AUTH_EMULATOR_HOST);
        try {
          connectAuthEmulator(auth, url, { disableWarnings: true });
          globalCache.emulators.auth = true;
          log('auth emulator connected', url);
        } catch (error) {
          console.warn('[firebase] auth emulator connection failed', error);
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

  if (globalCache.firestore) {
    return globalCache.firestore;
  }

  const firestore = getFirestore(getFirebaseApp());

  if (EMULATOR_ENABLED && !globalCache.emulators.firestore) {
    const { host, port } = parseHostAndPort(FIRESTORE_EMULATOR_HOST);
    try {
      connectFirestoreEmulator(firestore, host, port);
      globalCache.emulators.firestore = true;
      log('firestore emulator connected', `${host}:${port}`);
    } catch (error) {
      console.warn('[firebase] firestore emulator connection failed', error);
    }
  }

  globalCache.firestore = firestore;
  return firestore;
}

export function isFirebaseClientConfigured(): boolean {
  if (cachedConfig) {
    return true;
  }
  if (cachedConfigError) {
    if (!missingLogged) {
      console.warn('[firebase] missing client configuration keys:', cachedConfigError.missing);
      missingLogged = true;
    }
    return false;
  }

  try {
    resolveConfig();
    return true;
  } catch (error) {
    if (error instanceof FirebaseClientConfigError) {
      if (!missingLogged) {
        console.warn('[firebase] missing client configuration keys:', error.missing);
        missingLogged = true;
      }
      return false;
    }
    throw error;
  }
}
