import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { getDeploymentStage } from '@/src/config/sites';
import { ADMIN_SESSION_COOKIE, DEV_ROLE_COOKIE } from '@/src/lib/auth/constants';
import type { Role } from '@/src/lib/auth/types';
import {
  ADMIN_ROUTES,
  DEFAULT_AFTER_LOGIN,
  PORTAL_ROUTES,
  isAdminPath,
  isAdminProtectedPath,
  isMarketingPath,
  isPortalPath,
  isPortalProtectedPath,
  safeAfterLoginRoute,
} from '@/src/lib/routes';

const PORTAL_ALLOWED_ROLES: Role[] = ['admin', 'owner', 'operator'];
const ADMIN_SESSION_API_PATH = '/api/admin/auth/session';

function isStaticAsset(pathname: string): boolean {
  return (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/favicon.ico') ||
    pathname.startsWith('/icon.svg') ||
    pathname.startsWith('/images/')
  );
}

function allowApiRoute(pathname: string): boolean {
  return pathname.startsWith('/api/dev') || pathname.startsWith(ADMIN_SESSION_API_PATH);
}

function buildPortalLoginUrl(request: NextRequest, nextPathname: string) {
  const loginUrl = request.nextUrl.clone();
  loginUrl.pathname = PORTAL_ROUTES.login.href;
  loginUrl.hash = '';
  loginUrl.search = '';
  loginUrl.searchParams.set('next', safeAfterLoginRoute(nextPathname));
  return loginUrl;
}

function buildAdminLoginUrl(request: NextRequest, nextPathname: string) {
  const loginUrl = request.nextUrl.clone();
  loginUrl.pathname = ADMIN_ROUTES.login.href;
  loginUrl.hash = '';
  loginUrl.search = '';
  const safeTarget = safeAfterLoginRoute(nextPathname);
  const target = safeTarget === DEFAULT_AFTER_LOGIN ? ADMIN_ROUTES.dashboard.href : safeTarget;
  loginUrl.searchParams.set('next', target);
  return loginUrl;
}

async function hasValidAdminSession(request: NextRequest): Promise<boolean> {
  const sessionCookie = request.cookies.get(ADMIN_SESSION_COOKIE)?.value;
  if (!sessionCookie) {
    return false;
  }

  try {
    const response = await fetch(new URL(ADMIN_SESSION_API_PATH, request.url), {
      method: 'GET',
      headers: {
        cookie: request.headers.get('cookie') ?? '',
      },
    });

    return response.ok;
  } catch (error) {
    console.error('[middleware] admin session validation failed', error);
    return false;
  }
}

function redirectTo(pathname: string, request: NextRequest) {
  const url = request.nextUrl.clone();
  url.pathname = pathname;
  url.search = '';
  url.hash = '';
  return url;
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (isStaticAsset(pathname) || allowApiRoute(pathname)) {
    return NextResponse.next();
  }

  if (isAdminPath(pathname)) {
    const stage = getDeploymentStage();
    const devRole = request.cookies.get(DEV_ROLE_COOKIE)?.value as Role | undefined;
    const hasDevAdmin = stage !== 'production' && devRole === 'admin';

    if (pathname === ADMIN_ROUTES.login.href) {
      if (hasDevAdmin || (await hasValidAdminSession(request))) {
        const target = redirectTo(ADMIN_ROUTES.dashboard.href, request);
        return NextResponse.redirect(target);
      }

      return NextResponse.next();
    }

    if (pathname === ADMIN_ROUTES.logout.href) {
      return NextResponse.next();
    }

    if (!isAdminProtectedPath(pathname)) {
      return NextResponse.next();
    }

    if (hasDevAdmin) {
      return NextResponse.next();
    }

    const sessionCookie = request.cookies.get(ADMIN_SESSION_COOKIE)?.value;
    const sessionValid = await hasValidAdminSession(request);

    if (sessionValid) {
      return NextResponse.next();
    }

    if (sessionCookie) {
      const forbiddenUrl = redirectTo('/403', request);
      return NextResponse.rewrite(forbiddenUrl, { status: 403 });
    }

    const loginUrl = buildAdminLoginUrl(request, pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (isPortalPath(pathname)) {
    if (pathname === PORTAL_ROUTES.home.href) {
      const target = redirectTo(PORTAL_ROUTES.gym.href, request);
      return NextResponse.redirect(target);
    }

    if (isPortalProtectedPath(pathname)) {
      const role = request.cookies.get(DEV_ROLE_COOKIE)?.value as Role | undefined;
      if (!role || !PORTAL_ALLOWED_ROLES.includes(role)) {
        const loginUrl = buildPortalLoginUrl(request, pathname);
        return NextResponse.redirect(loginUrl);
      }
    }

    return NextResponse.next();
  }

  if (isMarketingPath(pathname)) {
    return NextResponse.next();
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image).*)'],
};
