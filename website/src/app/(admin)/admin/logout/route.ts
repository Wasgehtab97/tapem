import { NextResponse } from 'next/server';

import { MARKETING_ROUTES } from '@/src/lib/routes';
import { clearSessionCookie } from '@/src/server/auth/session';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET(request: Request) {
  const url = new URL(request.url);
  url.pathname = MARKETING_ROUTES.home.href;
  url.search = '';

  const response = NextResponse.redirect(url, { status: 302 });
  response.headers.set('Cache-Control', 'no-store');
  clearSessionCookie(response);
  return response;
}
