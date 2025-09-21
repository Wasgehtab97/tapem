import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { getDeploymentStage } from '@/config/sites';
import { ADMIN_SESSION_COOKIE, DEV_ROLE_COOKIE } from '@/lib/auth/constants';
import type { Role } from '@/lib/auth/types';
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
} from '@/lib/routes';
import { isDevPreviewRoleSwitchesEnabled } from '@/lib/env';

const PORTAL_ALLOWED_ROLES: Role[] = ['admin', 'owner', 'operator'];
const ADMIN_SESSION_API_PATH = '/api/auth/me';
const ADMIN_HEALTH_API_PATH = '/api/health/firebase-admin';

function isStaticAsset(pathname: string): boolean {
  return (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/favicon.ico') ||
    pathname.startsWith('/icon.svg') ||
    pathname.startsWith('/images/')
  );
}

function allowApiRoute(pathname: string): boolean {
  return (
    pathname.startsWith('/api/dev') ||
    pathname.startsWith('/api/auth') ||
    pathname.startsWith(ADMIN_SESSION_API_PATH) ||
    pathname.startsWith(ADMIN_HEALTH_API_PATH)
  );
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
  if (!sessionCookie) return false;

  try {
    const response = await fetch(new URL(ADMIN_SESSION_API_PATH, request.url), {
      method: 'GET',
      headers: {
        cookie: request.headers.get('cookie') ?? '',
      },
      cache: 'no-store',
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

  // 1) Statische Assets & freigegebene API-Routen durchlassen
  if (isStaticAsset(pathname) || allowApiRoute(pathname)) {
    return NextResponse.next();
  }

  // 2) ADMIN-Bereich
  if (isAdminPath(pathname)) {
    const stage = getDeploymentStage();
    const previewRolesEnabled = isDevPreviewRoleSwitchesEnabled();
    const devRole = previewRolesEnabled
      ? (request.cookies.get(DEV_ROLE_COOKIE)?.value as Role | undefined)
      : undefined;
    const hasDevAdmin = previewRolesEnabled && stage !== 'production' && devRole === 'admin';

    // Admin-Login
    if (pathname === ADMIN_ROUTES.login.href) {
      if (hasDevAdmin || (await hasValidAdminSession(request))) {
        return NextResponse.redirect(redirectTo(ADMIN_ROUTES.dashboard.href, request));
      }
      return NextResponse.next();
    }

    // Admin-Logout immer erlauben
    if (pathname === ADMIN_ROUTES.logout.href) {
      return NextResponse.next();
    }

    // Unprotected Admin-Seiten erlauben
    if (!isAdminProtectedPath(pathname)) {
      return NextResponse.next();
    }

    // Dev-Admin-Bypass
    if (hasDevAdmin) {
      return NextResponse.next();
    }

    // Geschützte Admin-Seiten → Session prüfen
    const hasCookie = Boolean(request.cookies.get(ADMIN_SESSION_COOKIE)?.value);
    const sessionValid = await hasValidAdminSession(request);

    if (sessionValid) return NextResponse.next();

    // Cookie vorhanden aber ungültig → 403-Seite
    if (hasCookie) {
      return NextResponse.rewrite(redirectTo('/403', request));
    }

    // Keine Session → zum Admin-Login
    return NextResponse.redirect(buildAdminLoginUrl(request, pathname));
  }

  // 3) PORTAL-Bereich
  if (isPortalPath(pathname)) {
    // /portal -> /portal/gym
    if (pathname === PORTAL_ROUTES.home.href) {
      return NextResponse.redirect(redirectTo(PORTAL_ROUTES.gym.href, request));
    }

    if (isPortalProtectedPath(pathname)) {
      const role = request.cookies.get(DEV_ROLE_COOKIE)?.value as Role | undefined;
      if (!role || !PORTAL_ALLOWED_ROLES.includes(role)) {
        return NextResponse.redirect(buildPortalLoginUrl(request, pathname));
      }
    }

    return NextResponse.next();
  }

  // 4) Marketing/sonstige Routen
  if (isMarketingPath(pathname)) {
    return NextResponse.next();
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image).*)'],
};
