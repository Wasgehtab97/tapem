'use client';

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

/**
 * WICHTIG:
 * In Next.js werden NUR statische Zugriffe wie process.env.NEXT_PUBLIC_… ersetzt.
 * Daher KEIN process.env[key] oder dynamische Maps benutzen!
 */
const API_KEY        = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
const AUTH_DOMAIN    = process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN;
const PROJECT_ID     = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
const APP_ID         = process.env.NEXT_PUBLIC_FIREBASE_APP_ID;

const STORAGE_BUCKET = process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET;
const MSG_SENDER     = process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID;
const MEASUREMENT_ID = process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID;

const DEBUG_BROWSER  = process.env.NEXT_PUBLIC_TAPEM_DEBUG === '1';

const USE_EMU        = process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATOR === 'true';
const AUTH_EMU_HOST  = process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST ?? 'localhost:9099';
const FS_EMU_HOST    = process.env.NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST ?? 'localhost:8080';

const log = (...a: any[]) => { if (DEBUG_BROWSER) console.log('[firebase:client]', ...a); };

function required(v: string | undefined | null): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

function resolveConfig(): FirebaseOptions {
  const missing: string[] = [];
  if (!required(API_KEY))     missing.push('NEXT_PUBLIC_FIREBASE_API_KEY');
  if (!required(AUTH_DOMAIN)) missing.push('NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN');
  if (!required(PROJECT_ID))  missing.push('NEXT_PUBLIC_FIREBASE_PROJECT_ID');
  if (!required(APP_ID))      missing.push('NEXT_PUBLIC_FIREBASE_APP_ID');

  if (missing.length) {
    throw Object.assign(new Error(`Missing client env: ${missing.join(', ')}`), { missing });
  }

  // Storage-Bucket automatisch ableiten, falls nicht gesetzt
  const bucket = required(STORAGE_BUCKET) ? STORAGE_BUCKET : `${PROJECT_ID}.appspot.com`;

  const cfg: FirebaseOptions = {
    apiKey: API_KEY!,
    authDomain: AUTH_DOMAIN!,
    projectId: PROJECT_ID!,
    appId: APP_ID!,
    storageBucket: bucket,
    // optional:
    messagingSenderId: MSG_SENDER,
    measurementId: MEASUREMENT_ID,
  };
  return cfg;
}

function ensureBrowser() {
  if (typeof window === 'undefined') {
    throw new Error('Firebase client SDK darf nur im Browser verwendet werden.');
  }
}

// globales Cache-Objekt (HMR-sicher)
declare global {
  interface Window {
    __TAPEM_FB__?: { app?: FirebaseApp; auth?: Auth; db?: Firestore; emu?: boolean };
  }
}
const g = typeof window !== 'undefined' ? (window.__TAPEM_FB__ ||= {}) : {};

function initApp(): FirebaseApp {
  if (g.app) return g.app;
  ensureBrowser();

  const existing = getApps()[0];
  if (existing) {
    g.app = existing;
    return existing;
  }
  const cfg = resolveConfig();
  log('init app', cfg.projectId, { emulator: USE_EMU });
  g.app = initializeApp(cfg);
  return g.app;
}

let authInit: Promise<Auth> | null = null;
export async function getFirebaseAuth(): Promise<Auth> {
  ensureBrowser();
  if (g.auth) return g.auth;

  if (!authInit) {
    authInit = (async () => {
      const auth = getAuth(initApp());
      try {
        await setPersistence(auth, browserLocalPersistence);
      } catch (e) {
        console.warn('[firebase] setPersistence failed', e);
      }
      if (USE_EMU && !g.emu) {
        const url = AUTH_EMU_HOST.startsWith('http') ? AUTH_EMU_HOST : `http://${AUTH_EMU_HOST}`;
        try { connectAuthEmulator(auth, url, { disableWarnings: true }); log('auth emulator', url); }
        catch (e) { console.warn('[firebase] connectAuthEmulator failed', e); }
      }
      g.auth = auth;
      return auth;
    })();
  }
  return authInit;
}

export function getFirebaseFirestore(): Firestore {
  ensureBrowser();
  if (g.db) return g.db;

  const db = getFirestore(initApp());
  if (USE_EMU && !g.emu) {
    try {
      const [host, portStr = '8080'] = FS_EMU_HOST.split(':');
      connectFirestoreEmulator(db, host, Number(portStr));
      log('firestore emulator', `${host}:${portStr}`);
    } catch (e) {
      console.warn('[firebase] connectFirestoreEmulator failed', e);
    }
  }
  g.db = db;
  g.emu = true;
  return db;
}

export function getFirebaseApp(): FirebaseApp {
  return initApp();
}

/** true, wenn die 4 Minimal-Keys vorhanden sind */
export function isFirebaseClientConfigured(): boolean {
  try {
    resolveConfig();
    return true;
  } catch (e: any) {
    if (DEBUG_BROWSER) console.warn('[firebase] client config missing', e?.missing ?? e);
    return false;
  }
}
