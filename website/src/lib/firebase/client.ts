'use client';
import { initializeApp, getApps, type FirebaseApp, type FirebaseOptions } from 'firebase/app';
import {
  browserLocalPersistence, getAuth, setPersistence, connectAuthEmulator, type Auth,
} from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, type Firestore } from 'firebase/firestore';

const REQUIRED_ENV_KEYS = [
  'NEXT_PUBLIC_FIREBASE_API_KEY',
  'NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN',
  'NEXT_PUBLIC_FIREBASE_PROJECT_ID',
  'NEXT_PUBLIC_FIREBASE_APP_ID',
  'NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET',
  'NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID',
] as const;
type RequiredEnvKey = (typeof REQUIRED_ENV_KEYS)[number];

function readEnv(k: string) {
  const v = (process.env as Record<string, string | undefined>)[k];
  return typeof v === 'string' && v.trim() ? v : undefined;
}
const DEBUG = readEnv('NEXT_PUBLIC_TAPEM_DEBUG') === '1';
const log = (...a: any[]) => DEBUG && console.log('[firebase:client]', ...a);

export class FirebaseClientConfigError extends Error {
  constructor(public missing: RequiredEnvKey[]) {
    super(`Firebase client configuration is incomplete (missing: ${missing.join(', ')})`);
    this.name = 'FirebaseClientConfigError';
  }
}
function resolveConfig(): FirebaseOptions {
  const miss: RequiredEnvKey[] = [];
  const req = (k: RequiredEnvKey) => { const v = readEnv(k); if (!v) miss.push(k); return v; };
  const projectId = req('NEXT_PUBLIC_FIREBASE_PROJECT_ID');
  const storageBucket = readEnv('NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET') ?? (projectId ? `${projectId}.appspot.com` : undefined);
  const cfg: FirebaseOptions = {
    apiKey: req('NEXT_PUBLIC_FIREBASE_API_KEY'),
    authDomain: req('NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN'),
    projectId,
    appId: req('NEXT_PUBLIC_FIREBASE_APP_ID'),
    storageBucket,
    messagingSenderId: req('NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID'),
    measurementId: readEnv('NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID'),
  };
  if (miss.length) throw new FirebaseClientConfigError(miss);
  return cfg;
}

const USE_EMU = readEnv('NEXT_PUBLIC_USE_FIREBASE_EMULATOR') === 'true';
const AUTH_EMU = readEnv('NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST') ?? 'localhost:9099';
const FS_EMU = readEnv('NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST') ?? 'localhost:8080';

declare global {
  interface Window { __TAPEM_FB__?: { app?: FirebaseApp; auth?: Auth; db?: Firestore; emu?: boolean } }
}
const g = typeof window === 'undefined' ? {} as any : (window.__TAPEM_FB__ ||= {});

function ensureBrowser() {
  if (typeof window === 'undefined') throw new Error('Firebase client SDK may only be used in the browser.');
}

export function getFirebaseApp(): FirebaseApp {
  ensureBrowser();
  if (g.app) return g.app;
  const existing = getApps()[0];
  if (existing) { g.app = existing; return existing; }
  const cfg = resolveConfig();
  log('init app', cfg.projectId, { emulator: USE_EMU });
  const app = initializeApp(cfg);
  g.app = app;
  return app;
}

let authInit: Promise<Auth> | null = null;
export async function getFirebaseAuth(): Promise<Auth> {
  ensureBrowser();
  if (g.auth) return g.auth;
  if (!authInit) {
    authInit = (async () => {
      const auth = getAuth(getFirebaseApp());
      try { await setPersistence(auth, browserLocalPersistence); } catch (e) { console.warn('[firebase] persistence', e); }
      if (USE_EMU && !g.emu) {
        const url = AUTH_EMU.startsWith('http') ? AUTH_EMU : `http://${AUTH_EMU}`;
        try { connectAuthEmulator(auth, url, { disableWarnings: true }); log('auth emulator', url); } catch (e) { console.warn('[firebase] auth emulator', e); }
      }
      g.auth = auth; return auth;
    })();
  }
  return authInit;
}

export function getFirebaseFirestore(): Firestore {
  ensureBrowser();
  if (g.db) return g.db;
  const db = getFirestore(getFirebaseApp());
  if (USE_EMU && !g.emu) {
    try { const [h,p='8080'] = FS_EMU.split(':'); connectFirestoreEmulator(db, h, Number(p)); log('fs emulator', `${h}:${p}`); } catch (e) { console.warn('[firebase] fs emulator', e); }
  }
  g.db = db; g.emu = true; return db;
}

export function isFirebaseClientConfigured(): boolean {
  try { resolveConfig(); return true; }
  catch (e) { if (e instanceof FirebaseClientConfigError) { console.warn('[firebase] missing', e.missing); return false; } throw e; }
}
