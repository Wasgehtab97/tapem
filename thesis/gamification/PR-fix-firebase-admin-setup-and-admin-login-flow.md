# PR: Fix Firebase Admin Setup & Admin Login Flow

## Ziel & Kontext
- Health-Check und Firebase-Admin-Bootstrap lieferten Fehler (fehlende Service-Account-Infos, 404 auf `/api/health/firebase-admin`).
- Der Admin-Login setzte keine Session-Cookies; Admin-Routen waren nur per dev-switch erreichbar.
- Firestore-Abfragen im Dashboard scheiterten mit `FAILED_PRECONDITION` aufgrund fehlender Indizes und erzeugten Laufzeitfehler.
- Zusätzlich gab es Theme-Color-Warnungen und unvollständige DX-Dokumentation für Env-Variablen und Emulator-Support.

## Verwendeter Prompt (vollständig)
```
Codex-Prompt — „Fix Firebase Admin + Loginflow (Next.js App Router)“

PR-Name: codex/fix-firebase-admin-setup-and-admin-login-flow
Repo-Pfad: website/ (Next.js 14 / App Router)

Ziele

Server: Firebase Admin SDK sicher initialisieren (Service-Account Base64 + Emulator-Support), Health-Check unter /api/health/firebase-admin.

Client: Firebase Web SDK richtig konfigurieren, nur auf Client nutzen, saubere Prüfung statt „false positive“ Warnbanner.

Loginflow: E-Mail/Passwort → idToken → Session-Cookie via API → Redirect /admin.

Schutz: Middleware: /admin/** nur mit Session-Cookie; Server-Guards.

Dashboard: Firestore-Abfragen ausschließlich über Admin SDK; FAILED_PRECONDITION (Indizes) robust abfangen + Fallback.

DX: viewport.themeColor statt metadata.themeColor, .env.example aktualisieren, Scripts für Diagnose.

Masterarbeit: .md unter thesis/gamification/ mit Prompt, Ziel/Kontext und Ergebnis anlegen.

Wichtig

Keine Secrets committen! Lies Server-Secrets nur aus Umgebungsvariablen.

Alle API-Routen und Server-Utils, die Admin SDK nutzen, Node-Runtime (nicht Edge).

Client-SDK nur in Dateien mit 'use client'.

Dateien: Ersetzen/Erstellen (1:1 Inhalte)

Falls Pfade minimal abweichen, analog anwenden. Alle Dateien im Ordner website/.

1) src/lib/firebase/client.ts ✅ (Client SDK, HMR-safe, Emulator optional)
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

2) src/components/admin/admin-login-form.tsx ✅ (nur Client-SDK + Session-Cookie)
'use client';
import React, { useState } from 'react';
import { getFirebaseAuth, isFirebaseClientConfigured } from '@/src/lib/firebase/client';
import { signInWithEmailAndPassword } from 'firebase/auth';

export default function AdminLoginForm() {
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const clientOk = isFirebaseClientConfigured();

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null); setBusy(true);
    try {
      if (!clientOk) throw new Error('client-not-configured');
      const auth = await getFirebaseAuth();
      const cred = await signInWithEmailAndPassword(auth, email.trim(), pw);
      const idToken = await cred.user.getIdToken(/* forceRefresh */ true);
      const resp = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      });
      if (!resp.ok) throw new Error('login-endpoint-failed');
      // Redirect to /admin
      window.location.href = '/admin';
    } catch (e: any) {
      setErr(e?.message ?? 'unknown-error');
    } finally { setBusy(false); }
  }

  return (
    <form onSubmit={onSubmit} className="grid gap-4">
      {!clientOk && (
        <div className="rounded-md bg-red-100/10 border border-red-400 p-3 text-red-200">
          Firebase ist noch nicht konfiguriert. Bitte die Umgebungsvariablen prüfen.
        </div>
      )}

      <label className="grid gap-2">
        <span className="text-sm opacity-80">E-Mail-Adresse</span>
        <input type="email" required value={email} onChange={e=>setEmail(e.target.value)} className="px-3 py-2 rounded-md bg-neutral-900 border border-neutral-700" />
      </label>

      <label className="grid gap-2">
        <span className="text-sm opacity-80">Passwort</span>
        <input type="password" required value={pw} onChange={e=>setPw(e.target.value)} className="px-3 py-2 rounded-md bg-neutral-900 border border-neutral-700" />
      </label>

      {err && <div className="text-sm text-red-300">{err}</div>}

      <button disabled={busy || !clientOk} className="rounded-md px-4 py-2 bg-blue-600 disabled:opacity-50">
        {busy ? 'Anmelden…' : 'Anmelden'}
      </button>
    </form>
  );
}

3) src/app/(admin)/admin/login/page.tsx ✅ (schlank)
import AdminLoginForm from '@/src/components/admin/admin-login-form';
import Link from 'next/link';

export const runtime = 'nodejs'; // page selbst ist RSC, ok
export const dynamic = 'force-dynamic';

export default async function Page() {
  // Optional: Health-Badge vom Server
  const r = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL ?? ''}/api/health/firebase-admin`, { cache: 'no-store' }).catch(()=>null);
  const info = r?.ok ? await r.json() : null;

  return (
    <div className="max-w-lg mx-auto py-10 grid gap-6">
      {info && (
        <div className="rounded-md bg-emerald-100/10 border border-emerald-400 p-3 text-emerald-200">
          Verbunden mit Projekt <b>{info.projectId}</b> · Modus <b>{info.mode}</b> · Service Account {info.usesServiceAccount ? 'aktiv' : 'inaktiv'}
        </div>
      )}
      <h1 className="text-2xl font-semibold">Anmeldung</h1>
      <AdminLoginForm />
      <p className="text-sm opacity-60">Bei Problemen: Core-Team kontaktieren.</p>
      <p className="text-xs opacity-40"><Link href="/">Zurück</Link></p>
    </div>
  );
}

4) src/server/firebase/admin.ts ✅ (Admin-SDK Singleton + Summary)
import 'server-only';
import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

type Mode = 'production' | 'emulator';

let app: App | null = null;
let mode: Mode = 'production';

function loadServiceAccountFromEnv():
  | { projectId: string; clientEmail: string; privateKey: string }
  | null {
  // Option A: einzeiliges Base64 JSON (empfohlen)
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (b64) {
    try {
      const json = JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
      return {
        projectId: json.project_id,
        clientEmail: json.client_email,
        privateKey: json.private_key?.replace(/\\n/g, '\n'),
      };
    } catch (e) {
      throw new Error('[firebase-admin] FIREBASE_SERVICE_ACCOUNT (base64) konnte nicht geparst werden.');
    }
  }
  // Option B: Einzelwerte
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;
  if (privateKey && privateKey.includes('\\n')) privateKey = privateKey.replace(/\\n/g, '\n');
  if (projectId && clientEmail && privateKey) return { projectId, clientEmail, privateKey };
  return null;
}

export function getFirebaseAdminApp(): App {
  if (app) return app;

  const svc = loadServiceAccountFromEnv();
  if (!svc) throw new Error('[firebase-admin] Service Account nicht gefunden – ENV prüfen.');

  const existing = getApps()[0];
  if (existing) {
    app = existing;
    return app;
  }

  // Emulator?
  if (process.env.USE_FIREBASE_EMULATOR === 'true') {
    process.env.FIRESTORE_EMULATOR_HOST ||= 'localhost:8080';
    process.env.FIREBASE_AUTH_EMULATOR_HOST ||= 'localhost:9099';
    mode = 'emulator';
  }

  app = initializeApp({
    credential: cert({ projectId: svc.projectId, clientEmail: svc.clientEmail, privateKey: svc.privateKey }),
    projectId: svc.projectId,
  }, 'tapem-admin-sdk');

  return app;
}

export function assertFirebaseAdminReady() {
  getFirebaseAdminApp(); // throws wenn nicht ok
}

export function getFirebaseAdminConfigSummary() {
  const svc = loadServiceAccountFromEnv();
  return {
    projectId: svc?.projectId ?? null,
    mode,
    usesServiceAccount: Boolean(svc),
  };
}

export const adminAuth = () => getAuth(getFirebaseAdminApp());
export const adminDb   = () => getFirestore(getFirebaseAdminApp());

...
```

## Umsetzung (Kurzfassung)
- Firebase Client- und Admin-SDKs als HMR-sichere Singletons neu implementiert, inklusive Emulator-Support & Config-Validierung.
- Login-Flow über `/api/auth/login`, Session-Cookies und Middleware-Schutz komplett neu aufgesetzt; Debug-Endpoints (`/api/auth/me`, `/api/auth/logout`) bereitgestellt.
- Admin-Dashboard nutzt jetzt ausschließlich `adminDb()` mit robustem Error-Handling und Fallbacks bei `FAILED_PRECONDITION` (Index-Hinweise, limitierte Queries).
- Health-Check `/api/health/firebase-admin` und Admin-Login-Seite aktualisiert (Health-Badge, schlankes UI, nur Client-SDK im Browser).
- DX-Verbesserungen: `.env.example` überarbeitet, viewport-themeColor korrigiert, Diagnose-Script bestätigt, Gamification-Log aktualisiert.

## Ergebnis (Screens/Checks)
- `npm run lint` & `npm run typecheck` (lokal) ✔️
- Manuelle Checks: Health-Endpoint gibt `{ ok: true }`, Login erzeugt `tapem_session`-Cookie und Redirect zu `/admin`, Logout entfernt das Cookie.
- Dashboard lädt Kennzahlen; bei fehlenden Indizes erscheinen Warnhinweise statt Abstürze.

## Lessons Learned
- Präzise Prompts mit detaillierten File-Replacements ermöglichen schnelles, deterministisches Arbeiten selbst bei umfangreichen Auth-/Firestore-Konfigurationen.
- Fallback-Strategien mit limitierten Queries halten Admin-UIs lauffähig, obwohl Firestore-Indizes noch erstellt werden.
- Einheitliche Env-Dokumentation reduziert Setup-Reibung erheblich.
