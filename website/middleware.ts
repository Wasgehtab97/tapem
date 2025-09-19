import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

import { buildSiteUrl, findSiteByHost } from '@/src/config/sites';
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
  resolveAllowedAfterLoginRoute,
} from '@/src/lib/routes';

const PORTAL_ALLOWED_ROLES: Role[] = ['admin', 'owner', 'operator'];
const ADMIN_REQUIRED_ROLE: Role = 'admin';

function isStaticAsset(pathname: string) {
  return (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/favicon.ico') ||
    pathname.startsWith('/icon.svg') ||
    pathname.startsWith('/images/')
  );
}

function allowApiRoute(pathname: string) {
  return pathname.startsWith('/api/dev');
}

function buildPortalLoginUrl(nextPathname: string | null) {
  const loginUrl = new URL(buildSiteUrl('portal', PORTAL_ROUTES.login));
  if (nextPathname && nextPathname !== PORTAL_ROUTES.home) {
    const safeTarget = resolveAllowedAfterLoginRoute(nextPathname);
    loginUrl.searchParams.set('next', safeTarget);
  } else {
    loginUrl.searchParams.set('next', DEFAULT_AFTER_LOGIN);
  }
  return loginUrl;
}

function redirectTo404(request: NextRequest) {
  const url = request.nextUrl.clone();
  url.pathname = '/404';
  url.search = '';
  return NextResponse.rewrite(url, { status: 404 });
}

export function middleware(request: NextRequest) {
  const host = request.headers.get('host');
  const site = findSiteByHost(host) ?? null;
  const pathname = request.nextUrl.pathname;

  if (!site) {
    return redirectTo404(request);
  }

  if (isStaticAsset(pathname) || allowApiRoute(pathname)) {
    return NextResponse.next();
  }

  if (site.key === 'marketing') {
    if (isMarketingPath(pathname)) {
      return NextResponse.next();
    }

    if (isPortalPath(pathname)) {
      if (isPortalProtectedPath(pathname)) {
        const loginUrl = buildPortalLoginUrl(pathname);
        return NextResponse.redirect(loginUrl);
      }
      const target = new URL(buildSiteUrl('portal', `${pathname}${request.nextUrl.search}`));
      return NextResponse.redirect(target);
    }

    if (isAdminPath(pathname)) {
      const target = new URL(buildSiteUrl('admin', `${pathname}${request.nextUrl.search}`));
      return NextResponse.redirect(target);
    }

    return redirectTo404(request);
  }

  if (site.key === 'portal') {
    if (!isPortalPath(pathname)) {
      return redirectTo404(request);
    }

    if (pathname === PORTAL_ROUTES.home) {
      const target = request.nextUrl.clone();
      target.pathname = PORTAL_ROUTES.gym;
      target.search = '';
      return NextResponse.redirect(target);
    }

    if (isPortalProtectedPath(pathname)) {
      const role = request.cookies.get('tapem_role')?.value as Role | undefined;
      if (!role || !PORTAL_ALLOWED_ROLES.includes(role)) {
        const loginUrl = buildPortalLoginUrl(pathname);
        return NextResponse.redirect(loginUrl);
      }
    }

    return NextResponse.next();
  }

  // site.key === 'admin'
  if (!isAdminPath(pathname)) {
    return redirectTo404(request);
  }

  if (pathname === ADMIN_ROUTES.home) {
    const target = request.nextUrl.clone();
    target.pathname = ADMIN_ROUTES.dashboard;
    target.search = '';
    return NextResponse.redirect(target);
  }

  if (isAdminProtectedPath(pathname)) {
    const role = request.cookies.get('tapem_role')?.value as Role | undefined;
    if (role !== ADMIN_REQUIRED_ROLE) {
      const url = request.nextUrl.clone();
      url.pathname = '/403';
      url.search = '';
      return NextResponse.rewrite(url, { status: 403 });
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image).*)'],
};
