// src/app/api/admin/auth/session/route.ts
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

import { NextResponse } from 'next/server';
import { ADMIN_SESSION_COOKIE } from '@/src/lib/auth/constants';
import {
  ADMIN_SESSION_MAX_AGE_SECONDS,
  AdminRoleRequiredError,
  createAdminSession,
  getAdminUserFromSession,
  revokeAdminSessionCookie,
} from '@/src/server/auth/session';
import { resolveCookieDomain, resolveCookieSecurity } from '@/src/server/auth/cookies';
import {
  FirebaseAdminConfigError,
  assertFirebaseAdminReady,
} from '@/src/server/firebase/admin';

function json(data: unknown, init?: number | ResponseInit) {
  const res = NextResponse.json(data, typeof init === 'number' ? { status: init } : init);
  // Admin-Auth nie cachen
  res.headers.set('Cache-Control', 'no-store');
  return res;
}

export async function GET() {
  try {
    // Stellt sicher, dass das Admin SDK korrekt konfiguriert ist
    assertFirebaseAdminReady();

    const user = await getAdminUserFromSession();
    if (!user) return json({ status: 'unauthorized' }, 401);

    return json(
      { status: 'ok', user: { uid: user.uid, email: user.email, role: user.role } },
      200
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Admin SDK not ready';
    console.error('[session GET]', message);
    return json({ status: 'misconfigured', message }, 500);
  }
}

export async function POST(request: Request) {
  let idToken: string | undefined;

  try {
    // Wir akzeptieren JSON und Form-POST (Fallback)
    const contentType = request.headers.get('content-type') ?? '';
    if (contentType.includes('application/json')) {
      const body = (await request.json()) as { idToken?: string };
      idToken = body?.idToken;
    } else {
      const form = await request.formData();
      const v = form.get('idToken');
      idToken = typeof v === 'string' ? v : undefined;
    }
  } catch {
    return json({ status: 'invalid_payload' }, 400);
  }

  if (!idToken) return json({ status: 'missing_id_token' }, 400);

  try {
    assertFirebaseAdminReady();

    const { cookieValue, user } = await createAdminSession(idToken);

    const domain = resolveCookieDomain(request);
    const secure = resolveCookieSecurity();

    const res = json(
      { status: 'ok', user: { uid: user.uid, email: user.email, role: user.role } },
      200
    );

    // Admin-Cookies: httpOnly + strict, im Dev NICHT secure
    res.cookies.set({
      name: ADMIN_SESSION_COOKIE,
      value: cookieValue,
      httpOnly: true,
      sameSite: 'strict',
      secure,
      maxAge: ADMIN_SESSION_MAX_AGE_SECONDS,
      path: '/',
      domain,
    });

    return res;
  } catch (error: unknown) {
    if (error instanceof AdminRoleRequiredError) {
      return json({ status: 'missing_admin_role' }, 403);
    }

    const codeFromError = (error as { code?: string })?.code;
    const errorInfo = (error as { errorInfo?: { code?: string } })?.errorInfo;
    const code = typeof codeFromError === 'string'
      ? codeFromError
      : typeof errorInfo?.code === 'string'
      ? errorInfo.code
      : undefined;

    if (error instanceof FirebaseAdminConfigError) {
      console.error('[session POST] config error', error.message);
      return json({ status: 'misconfigured', message: error.message }, 500);
    }

    if (code && code.startsWith('auth/')) {
      console.warn('[session POST] invalid id token', code);
      return json({ status: 'invalid-token', message: 'ID-Token konnte nicht verifiziert werden.' }, 401);
    }

    const message = error instanceof Error ? error.message : 'Unbekannter Fehler beim Erstellen der Session.';
    console.error('[session POST]', message);
    return json({ status: 'error', message }, 500);
  }
}

export async function DELETE(request: Request) {
  try {
    assertFirebaseAdminReady();
  } catch {
    // selbst wenn SDK down ist: Cookie beim Client löschen
  }

  // Aktuelles Cookie aus dem Header lesen (wir sind in einer Route Handler-Fn)
  const raw = request.headers.get('cookie') ?? '';
  const pair = raw
    .split(';')
    .map((p) => p.trim())
    .find((e) => e.startsWith(`${ADMIN_SESSION_COOKIE}=`));
  const cookieValue = pair ? pair.split('=').slice(1).join('=') : undefined;

  try {
    await revokeAdminSessionCookie(cookieValue);
  } catch (e) {
    // Wenn es nichts zu widerrufen gibt, ignorieren wir das – wir löschen das Cookie ohnehin clientseitig
    console.warn('[session DELETE] revoke failed (ignored):', (e as Error)?.message ?? e);
  }

  const domain = resolveCookieDomain(request);
  const secure = resolveCookieSecurity();

  const res = new NextResponse(null, { status: 204 });
  res.headers.set('Cache-Control', 'no-store');
  res.cookies.set({
    name: ADMIN_SESSION_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'strict',
    secure,
    maxAge: 0,
    path: '/',
    domain,
  });

  return res;
}
