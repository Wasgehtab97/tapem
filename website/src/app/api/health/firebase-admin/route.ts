import { NextResponse } from 'next/server';
import { assertFirebaseAdminReady, getFirebaseAdminConfigSummary } from '@/src/server/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET() {
  const headers = { 'Cache-Control': 'no-store' };
  try {
    assertFirebaseAdminReady();
    return NextResponse.json({ ok: true, ...getFirebaseAdminConfigSummary() }, { headers });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e?.message ?? e) }, { status: 500, headers });
  }
}
