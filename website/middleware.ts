import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { SESSION_COOKIE_NAME } from '@/src/server/auth/cookies';

export const config = { matcher: ['/admin/:path*'] };

export function middleware(req: NextRequest) {
  // Middleware läuft im Edge-Runtime → KEIN Admin-SDK hier!
  const has = req.cookies.has(SESSION_COOKIE_NAME);
  if (has) return NextResponse.next();
  const url = new URL('/admin/login', req.url);
  return NextResponse.redirect(url);
}
