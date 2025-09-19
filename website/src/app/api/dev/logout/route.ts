import { NextResponse } from 'next/server';

import { findSiteByHost, normalizeHost } from '@/src/config/sites';

const ROLE_COOKIE = 'tapem_role';
const EMAIL_COOKIE = 'tapem_email';

function resolveCookieDomain(request: Request): string | undefined {
  const headerHost = request.headers.get('host');
  const normalized = normalizeHost(headerHost);

  if (!normalized) {
    return undefined;
  }

  const [hostname] = normalized.split(':');
  if (!hostname || hostname.includes('localhost') || hostname.startsWith('127.')) {
    return undefined;
  }

  const site = findSiteByHost(normalized) ?? findSiteByHost(hostname);
  if (!site) {
    return undefined;
  }

  return hostname;
}

export async function POST(request: Request) {
  if (process.env.VERCEL_ENV === 'production') {
    return new Response('dev login disabled in production', { status: 403 });
  }

  const response = new NextResponse(null, { status: 204 });
  const secure = process.env.NODE_ENV === 'production';
  const domain = resolveCookieDomain(request);

  response.cookies.set({
    name: ROLE_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 0,
    path: '/',
    secure,
    domain,
  });

  response.cookies.set({
    name: EMAIL_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 0,
    path: '/',
    secure,
    domain,
  });

  return response;
}
