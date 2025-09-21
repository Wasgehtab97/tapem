import { NextResponse } from 'next/server';

import { ADMIN_SESSION_MAX_AGE_SECONDS, buildAdminSessionCookie } from '@/server/auth/cookies';
import {
  AdminRoleRequiredError,
  createAdminSession,
} from '@/server/auth/session';
import {
  FirebaseAdminConfigError,
  assertFirebaseAdminReady,
} from '@/server/firebase/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

function errorResponse(status: number, body: Record<string, unknown>) {
  const response = NextResponse.json(body, { status });
  response.headers.set('Cache-Control', 'no-store');
  return response;
}

export async function POST(request: Request) {
  let idToken: string | undefined;

  try {
    const contentType = request.headers.get('content-type') ?? '';
    if (contentType.includes('application/json')) {
      const payload = (await request.json()) as Partial<{ idToken: string }>;
      idToken = payload.idToken?.trim();
    } else if (contentType.includes('application/x-www-form-urlencoded')) {
      const form = await request.formData();
      const raw = form.get('idToken');
      idToken = typeof raw === 'string' ? raw.trim() : undefined;
    }
  } catch {
    return errorResponse(400, { error: 'invalid_payload' });
  }

  if (!idToken) {
    return errorResponse(400, { error: 'missing_id_token' });
  }

  try {
    assertFirebaseAdminReady();
    const { cookieValue, expiresIn } = await createAdminSession(idToken);

    const response = new NextResponse(null, { status: 204 });
    response.headers.set('Cache-Control', 'no-store');
    response.headers.set('X-Session-Max-Age', String(ADMIN_SESSION_MAX_AGE_SECONDS));
    response.headers.set('X-Session-Expires-In', String(expiresIn));

    const cookie = buildAdminSessionCookie(request, cookieValue, ADMIN_SESSION_MAX_AGE_SECONDS);
    response.cookies.set(cookie);

    return response;
  } catch (error) {
    if (error instanceof AdminRoleRequiredError) {
      return errorResponse(403, { error: 'missing_admin_role' });
    }

    if (error instanceof FirebaseAdminConfigError) {
      return errorResponse(500, { error: 'misconfigured', message: error.message });
    }

    const code = (error as { code?: unknown })?.code;
    if (typeof code === 'string' && code.startsWith('auth/')) {
      return errorResponse(401, { error: 'invalid_token' });
    }

    const message = error instanceof Error ? error.message : 'Unbekannter Fehler beim Erstellen der Session.';
    console.error('[auth/login] unexpected error', error);
    return errorResponse(500, { error: 'internal_error', message });
  }
}
