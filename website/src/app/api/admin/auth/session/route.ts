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

function buildMissingIdTokenResponse() {
  return NextResponse.json({ error: 'missing_id_token' }, { status: 400 });
}

export async function GET() {
  const user = await getAdminUserFromSession();
  if (!user) {
    return NextResponse.json({ status: 'unauthorized' }, { status: 401 });
  }

  return NextResponse.json(
    { status: 'ok', user: { uid: user.uid, email: user.email, role: user.role } },
    { status: 200 }
  );
}

export async function POST(request: Request) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';

  let idToken: string | undefined;
  try {
    const contentType = request.headers.get('content-type') ?? '';
    if (contentType.includes('application/json')) {
      const body = (await request.json()) as { idToken?: string };
      idToken = body.idToken;
    } else {
      const formData = await request.formData();
      const tokenCandidate = formData.get('idToken');
      idToken = typeof tokenCandidate === 'string' ? tokenCandidate : undefined;
    }
  } catch {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  if (!idToken) {
    return buildMissingIdTokenResponse();
  }

  try {
    const { cookieValue, user } = await createAdminSession(idToken);
    const response = NextResponse.json(
      { status: 'ok', user: { uid: user.uid, email: user.email, role: user.role } },
      { status: 200 }
    );
    const domain = resolveCookieDomain(request);
    const secure = resolveCookieSecurity(request) || isProduction;

    response.cookies.set({
      name: ADMIN_SESSION_COOKIE,
      value: cookieValue,
      httpOnly: true,
      sameSite: 'lax',
      secure,
      maxAge: ADMIN_SESSION_MAX_AGE_SECONDS,
      path: '/',
      domain,
    });

    return response;
  } catch (error) {
    if (error instanceof AdminRoleRequiredError) {
      return NextResponse.json({ error: 'missing_admin_role' }, { status: 403 });
    }

    console.error('[auth] failed to create admin session', error);
    return NextResponse.json({ error: 'session_creation_failed' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';
  const cookieHeader = request.headers.get('cookie') ?? '';
  const currentCookie = cookieHeader
    .split(';')
    .map((part) => part.trim())
    .find((entry) => entry.startsWith(`${ADMIN_SESSION_COOKIE}=`));

  const cookieValue = currentCookie ? currentCookie.split('=').slice(1).join('=') : undefined;
  await revokeAdminSessionCookie(cookieValue);

  const response = new NextResponse(null, { status: 204 });
  const domain = resolveCookieDomain(request);
  const secure = resolveCookieSecurity(request) || isProduction;

  response.cookies.set({
    name: ADMIN_SESSION_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    secure,
    maxAge: 0,
    path: '/',
    domain,
  });

  return response;
}
