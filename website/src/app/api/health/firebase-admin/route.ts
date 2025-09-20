// src/app/api/health/firebase-admin/route.ts
import { NextResponse } from 'next/server';

import {
  FirebaseAdminConfigError,
  assertFirebaseAdminReady,
  getFirebaseAdminApp,
  getFirebaseAdminConfigSummary,
} from '@/src/server/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

function json(body: unknown, status = 200) {
  const response = NextResponse.json(body, { status });
  response.headers.set('Cache-Control', 'no-store');
  return response;
}

export async function GET() {
  try {
    assertFirebaseAdminReady();
    const summary = getFirebaseAdminConfigSummary();
    if (summary) {
      return json({ ok: true, ...summary });
    }

    const app = getFirebaseAdminApp();
    return json({
      ok: true,
      projectId: app.options.projectId ?? process.env.FIREBASE_PROJECT_ID ?? 'unknown',
      mode: 'production',
      usesServiceAccount: true,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unbekannter Fehler beim Firebase Health-Check.';
    const status = error instanceof FirebaseAdminConfigError ? 500 : 500;
    return json({ ok: false, error: message }, status);
  }
}
