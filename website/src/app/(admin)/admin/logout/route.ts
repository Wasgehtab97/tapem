import { NextResponse } from 'next/server';

import { MARKETING_ROUTES } from '@/lib/routes';
import { revokeAdminSessionCookie } from '@/server/auth/session';
import { ADMIN_SESSION_COOKIE_NAME, buildAdminSessionCookie } from '@/server/auth/cookies';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET(request: Request) {
  const cookieHeader = request.headers.get('cookie') ?? '';
  const currentCookie = cookieHeader
    .split(';')
    .map((part) => part.trim())
    .find((entry) => entry.startsWith(`${ADMIN_SESSION_COOKIE_NAME}=`));

  const cookieValue = currentCookie ? currentCookie.split('=').slice(1).join('=') : undefined;
  await revokeAdminSessionCookie(cookieValue);

  const url = new URL(request.url);
  url.pathname = MARKETING_ROUTES.home.href;
  url.search = '';
  const response = NextResponse.redirect(url, { status: 302 });

  response.headers.set('Cache-Control', 'no-store');
  response.cookies.set(buildAdminSessionCookie(request, '', 0));

  return response;
}
