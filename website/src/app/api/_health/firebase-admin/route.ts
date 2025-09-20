import { NextResponse } from 'next/server';

import {
  assertFirebaseAdminReady,
  getFirebaseAdminApp,
  getFirebaseAdminConfigSummary,
} from '@/src/server/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET() {
  const toJson = (body: Record<string, unknown>, status: number) => {
    const response = NextResponse.json(body, { status });
    response.headers.set('Cache-Control', 'no-store');
    return response;
  };

  try {
    assertFirebaseAdminReady();
    const summary = getFirebaseAdminConfigSummary();

    if (!summary) {
      return toJson(
        {
          ok: false,
          error: 'Firebase Admin Konfiguration konnte nicht ermittelt werden.',
        },
        500
      );
    }

    const projectId = summary.projectId ?? getFirebaseAdminApp().options.projectId ?? 'unknown';

    return toJson(
      {
        ok: true,
        projectId,
        using: summary.using,
      },
      200
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unbekannter Fehler beim Firebase Admin Check.';
    return toJson({ ok: false, error: message }, 500);
  }
}
