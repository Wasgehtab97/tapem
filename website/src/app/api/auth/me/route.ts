import { NextResponse } from 'next/server';

import { getAdminUserFromSession } from '@/server/auth/session';
import { assertFirebaseAdminReady } from '@/server/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

function respond(body: Record<string, unknown>, status: number) {
  const response = NextResponse.json(body, { status });
  response.headers.set('Cache-Control', 'no-store');
  return response;
}

export async function GET() {
  try {
    assertFirebaseAdminReady();
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Firebase Admin ist nicht konfiguriert.';
    return respond({ error: 'misconfigured', message }, 500);
  }

  const user = await getAdminUserFromSession();
  if (!user) {
    return respond({ error: 'unauthorized' }, 401);
  }

  return respond(
    {
      ok: true,
      user: {
        uid: user.uid,
        email: user.email,
        role: user.role,
        source: user.source,
        roleSource: user.roleSource,
      },
    },
    200
  );
}
