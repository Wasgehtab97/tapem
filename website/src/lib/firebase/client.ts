'use client';

import { initializeApp, getApps, type FirebaseApp, type FirebaseOptions } from 'firebase/app';
import {
  browserLocalPersistence,
  getAuth,
  setPersistence,
  type Auth,
} from 'firebase/auth';
import { getFirestore, type Firestore } from 'firebase/firestore';

const REQUIRED_ENV_KEYS = [
  'NEXT_PUBLIC_FIREBASE_API_KEY',
  'NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN',
  'NEXT_PUBLIC_FIREBASE_PROJECT_ID',
  'NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET',
  'NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID',
  'NEXT_PUBLIC_FIREBASE_APP_ID',
] as const;

type RequiredEnvKey = (typeof REQUIRED_ENV_KEYS)[number];

type FirebaseClientConfig = FirebaseOptions;

export class FirebaseClientConfigError extends Error {
  public readonly missingKeys: RequiredEnvKey[];

  constructor(message: string, missingKeys: RequiredEnvKey[]) {
    super(message);
    this.name = 'FirebaseClientConfigError';
    this.missingKeys = missingKeys;
  }
}

let cachedApp: FirebaseApp | null = null;
let cachedFirestore: Firestore | null = null;
let authPromise: Promise<Auth> | null = null;

function readEnvValue(key: RequiredEnvKey): string | undefined {
  if (typeof process === 'undefined' || !process.env) {
    return undefined;
  }

  const value = process.env[key];
  if (typeof value !== 'string' || value.trim().length === 0) {
    return undefined;
  }

  return value;
}

function resolveClientConfig(): FirebaseClientConfig {
  const missing: RequiredEnvKey[] = [];
  const config: Partial<FirebaseClientConfig> = {};

  for (const key of REQUIRED_ENV_KEYS) {
    const value = readEnvValue(key);
    if (!value) {
      missing.push(key);
      continue;
    }

    switch (key) {
      case 'NEXT_PUBLIC_FIREBASE_API_KEY':
        config.apiKey = value;
        break;
      case 'NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN':
        config.authDomain = value;
        break;
      case 'NEXT_PUBLIC_FIREBASE_PROJECT_ID':
        config.projectId = value;
        break;
      case 'NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET':
        config.storageBucket = value;
        break;
      case 'NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID':
        config.messagingSenderId = value;
        break;
      case 'NEXT_PUBLIC_FIREBASE_APP_ID':
        config.appId = value;
        break;
      default:
        break;
    }
  }

  if (missing.length > 0) {
    throw new FirebaseClientConfigError(
      `Firebase client configuration is incomplete (missing: ${missing.join(', ')})`,
      missing,
    );
  }

  return config as FirebaseClientConfig;
}

function ensureIsBrowser() {
  if (typeof window === 'undefined') {
    throw new FirebaseClientConfigError('Firebase client is only available in the browser.', []);
  }
}

function initializeClientApp(): FirebaseApp {
  if (cachedApp) {
    return cachedApp;
  }

  ensureIsBrowser();
  const apps = getApps();
  if (apps.length > 0) {
    cachedApp = apps[0];
    return cachedApp;
  }

  const config = resolveClientConfig();
  cachedApp = initializeApp(config);
  return cachedApp;
}

export function getFirebaseApp(): FirebaseApp {
  return initializeClientApp();
}

export async function getFirebaseAuth(): Promise<Auth> {
  ensureIsBrowser();

  if (!authPromise) {
    const app = initializeClientApp();
    const auth = getAuth(app);
    authPromise = setPersistence(auth, browserLocalPersistence)
      .catch((error) => {
        console.error('[firebase] failed to set persistence', error);
        return auth;
      })
      .then(() => auth);
  }

  return authPromise;
}

export function getFirebaseFirestore(): Firestore {
  ensureIsBrowser();

  if (!cachedFirestore) {
    const app = initializeClientApp();
    cachedFirestore = getFirestore(app);
  }

  return cachedFirestore;
}

export function isFirebaseClientConfigured(): boolean {
  try {
    resolveClientConfig();
    return true;
  } catch (error) {
    if (error instanceof FirebaseClientConfigError) {
      console.warn('[firebase] client configuration missing keys', error.missingKeys);
      return false;
    }
    throw error;
  }
}
