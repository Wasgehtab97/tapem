// src/app/api/admin/auth/session/route.ts
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

import { NextResponse } from 'next/server';
import { getDeploymentStage } from '@/src/config/sites';
import { ADMIN_SESSION_COOKIE } from '@/src/lib/auth/constants';
import {
  ADMIN_SESSION_MAX_AGE_SECONDS,
  AdminRoleRequiredError,
  createAdminSession,
  getAdminUserFromSession,
  revokeAdminSessionCookie,
} from '@/src/server/auth/session';
import { resolveCookieDomain, resolveCookieSecurity } from '@/src/server/auth/cookies';
import { assertFirebaseAdminReady } from '@/src/server/firebase/admin';

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
  } catch (e: any) {
    console.error('[session GET]', e?.message ?? e);
    return json(
      { status: 'misconfigured', message: e?.message ?? 'Admin SDK not ready' },
      500
    );
  }
}

export async function POST(request: Request) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';

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
    return json({ error: 'invalid_payload' }, 400);
  }

  if (!idToken) return json({ error: 'missing_id_token' }, 400);

  try {
    assertFirebaseAdminReady();

    const { cookieValue, user } = await createAdminSession(idToken);

    const domain = resolveCookieDomain(request);
    const secure = resolveCookieSecurity(request) || isProduction;

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
  } catch (error: any) {
    if (error instanceof AdminRoleRequiredError) {
      return json({ error: 'missing_admin_role' }, 403);
    }
    console.error('[session POST]', error?.message ?? error);
    // Konfig-Fehler klar ausweisen – hilft dir beim Debuggen des Login-Banners
    return json(
      {
        error: 'session_creation_failed',
        reason:
          typeof error?.message === 'string'
            ? error.message
            : 'Admin SDK not ready or token invalid',
      },
      500
    );
  }
}

export async function DELETE(request: Request) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';

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
  const secure = resolveCookieSecurity(request) || isProduction;

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
