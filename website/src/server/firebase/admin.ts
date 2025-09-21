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
