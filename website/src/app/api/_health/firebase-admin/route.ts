// website/src/app/api/_health/firebase-admin/route.ts
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

import { NextResponse } from 'next/server';
import { getFirebaseAdminApp } from '@/src/server/firebase/admin';

function toJson(body: unknown, status = 200) {
  const res = NextResponse.json(body, { status });
  res.headers.set('Cache-Control', 'no-store');
  return res;
}

export async function GET() {
  try {
    // erzwingt Admin-SDK-Init (wirft bei Misconfig)
    getFirebaseAdminApp();

    const mode =
      process.env.FIREBASE_SERVICE_ACCOUNT?.trim()
        ? 'b64'
        : process.env.FIREBASE_PRIVATE_KEY?.trim()
        ? 'trio'
        : 'unknown';

    // bestmögliche Projekt-ID (ohne Secrets zu leaken)
    let projectId: string | null =
      process.env.FIREBASE_PROJECT_ID ??
      process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ??
      null;

    if (!projectId && process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const json = JSON.parse(
          Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8')
        );
        projectId = json?.project_id ?? null;
      } catch {
        // ignorieren – wir liefern trotzdem ok:true, aber ohne projectId
      }
    }

    return toJson({ ok: true, projectId, mode });
  } catch (e: any) {
    return toJson(
      { ok: false, error: e?.message ?? 'Admin SDK not ready' },
      500
    );
  }
}
