import { NextResponse } from 'next/server';

import { buildSiteUrl } from '@/src/config/sites';
import { MARKETING_ROUTES } from '@/src/lib/routes';
import {
  ADMIN_SESSION_COOKIE,
  revokeAdminSessionCookie,
} from '@/src/server/auth/session';
import { resolveCookieDomain, resolveCookieSecurity } from '@/src/server/auth/cookies';

export async function GET(request: Request) {
  const cookieHeader = request.headers.get('cookie') ?? '';
  const currentCookie = cookieHeader
    .split(';')
    .map((part) => part.trim())
    .find((entry) => entry.startsWith(`${ADMIN_SESSION_COOKIE}=`));

  const cookieValue = currentCookie ? currentCookie.split('=').slice(1).join('=') : undefined;
  await revokeAdminSessionCookie(cookieValue);

  const target = buildSiteUrl('marketing', MARKETING_ROUTES.home.href);
  const response = NextResponse.redirect(target, { status: 302 });
  const domain = resolveCookieDomain(request);
  const secure = resolveCookieSecurity(request);

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
