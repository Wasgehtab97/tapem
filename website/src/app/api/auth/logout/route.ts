import { NextResponse } from 'next/server';

import { ADMIN_SESSION_COOKIE_NAME, buildAdminSessionCookie } from '@/server/auth/cookies';
import { revokeAdminSessionCookie } from '@/server/auth/session';
import { assertFirebaseAdminReady } from '@/server/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

function extractSessionCookie(request: Request): string | undefined {
  const cookieHeader = request.headers.get('cookie');
  if (!cookieHeader) {
    return undefined;
  }

  const target = cookieHeader
    .split(';')
    .map((part) => part.trim())
    .find((part) => part.startsWith(`${ADMIN_SESSION_COOKIE_NAME}=`));

  if (!target) {
    return undefined;
  }

  return target.split('=').slice(1).join('=');
}

export async function POST(request: Request) {
  const cookieValue = extractSessionCookie(request);

  try {
    assertFirebaseAdminReady();
  } catch {
    // Wenn Firebase nicht bereit ist, löschen wir das Cookie trotzdem.
  }

  await revokeAdminSessionCookie(cookieValue);

  const response = new NextResponse(null, { status: 204 });
  response.headers.set('Cache-Control', 'no-store');
  const clearingCookie = buildAdminSessionCookie(request, '', 0);
  response.cookies.set(clearingCookie);

  return response;
}
