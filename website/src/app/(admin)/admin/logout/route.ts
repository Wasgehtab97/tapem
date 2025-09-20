import { NextResponse } from 'next/server';

import { ADMIN_SESSION_COOKIE } from '@/src/lib/auth/constants';
import { MARKETING_ROUTES } from '@/src/lib/routes';
import { revokeAdminSessionCookie } from '@/src/server/auth/session';
import { resolveCookieDomain, resolveCookieSecurity } from '@/src/server/auth/cookies';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET(request: Request) {
  const cookieHeader = request.headers.get('cookie') ?? '';
  const currentCookie = cookieHeader
    .split(';')
    .map((part) => part.trim())
    .find((entry) => entry.startsWith(`${ADMIN_SESSION_COOKIE}=`));

  const cookieValue = currentCookie ? currentCookie.split('=').slice(1).join('=') : undefined;
  await revokeAdminSessionCookie(cookieValue);

  const url = new URL(request.url);
  url.pathname = MARKETING_ROUTES.home.href;
  url.search = '';
  const response = NextResponse.redirect(url, { status: 302 });
  const domain = resolveCookieDomain(request);
  const secure = resolveCookieSecurity();

  response.headers.set('Cache-Control', 'no-store');
  response.cookies.set({
    name: ADMIN_SESSION_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'strict',
    secure,
    maxAge: 0,
    path: '/',
    domain,
  });

  return response;
}
