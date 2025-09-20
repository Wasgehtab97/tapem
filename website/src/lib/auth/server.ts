import 'server-only';

import { cookies, headers } from 'next/headers';
import { notFound, redirect } from 'next/navigation';

import { DEV_ROLE_COOKIE } from '@/src/lib/auth/constants';
import { getDeploymentStage } from '@/src/config/sites';
import {
  ADMIN_ROUTES,
  DEFAULT_AFTER_LOGIN,
  buildAdminLoginRedirectRoute,
  buildPortalLoginRedirectRoute,
  isAfterLoginRoute,
  safeAfterLoginRoute,
  type AfterLoginRoute,
  type AdminAfterLoginRoute,
} from '@/src/lib/routes';
import {
  getAdminUserFromSession,
} from '@/src/server/auth/session';

import type { AuthenticatedUser, DevUser, Role } from './types';

const ROLE_COOKIE = DEV_ROLE_COOKIE;
const EMAIL_COOKIE = 'tapem_email';
const DEFAULT_EMAIL = 'anonymous@tapem.dev';
const ROLES: Role[] = ['admin', 'owner', 'operator'];

function getNextAfterLoginRoute(): AfterLoginRoute {
  const headerList = headers();
  const candidates = [
    headerList.get('x-next-url'),
    headerList.get('next-url'),
    headerList.get('referer'),
  ];

  for (const candidate of candidates) {
    if (isAfterLoginRoute(candidate)) {
      return safeAfterLoginRoute(candidate);
    }
  }

  return DEFAULT_AFTER_LOGIN;
}

export function getDevUserFromCookies(): DevUser | null {
  const cookieStore = cookies();
  const role = cookieStore.get(ROLE_COOKIE)?.value as Role | undefined;

  if (!role || !ROLES.includes(role)) {
    return null;
  }

  const emailCookie = cookieStore.get(EMAIL_COOKIE)?.value;
  const email = emailCookie && emailCookie.trim().length > 0 ? emailCookie : DEFAULT_EMAIL;

  return {
    uid: `dev-${role}`,
    email,
    role,
  };
}

function mapDevUserToAuthenticated(user: DevUser): AuthenticatedUser {
  return {
    uid: user.uid,
    email: user.email,
    role: user.role,
    displayName: null,
    source: 'dev-stub',
  };
}

async function resolveAuthenticatedUser(allowed: Role[]): Promise<AuthenticatedUser | null> {
  const stage = getDeploymentStage();

  const sessionUser = await getAdminUserFromSession();
  if (sessionUser && allowed.includes(sessionUser.role)) {
    return sessionUser;
  }

  const allowDevFallback =
    stage !== 'production' || allowed.some((role) => role === 'owner' || role === 'operator');

  if (!allowDevFallback) {
    return null;
  }

  const devUser = getDevUserFromCookies();
  if (!devUser || !allowed.includes(devUser.role)) {
    return null;
  }

  return mapDevUserToAuthenticated(devUser);
}

type RequireRoleOptions = {
  failure?: 'redirect-to-login' | 'not-found';
  loginSite?: 'portal' | 'admin';
};

function resolveLoginSite(allowed: Role[], override?: 'portal' | 'admin'): 'portal' | 'admin' {
  if (override) {
    return override;
  }

  if (allowed.includes('owner') || allowed.includes('operator')) {
    return 'portal';
  }

  return allowed.includes('admin') ? 'admin' : 'portal';
}

export async function requireRole(allowed: Role[], options?: RequireRoleOptions) {
  const user = await resolveAuthenticatedUser(allowed);

  if (user) {
    return { user } as const;
  }

  if (options?.failure === 'not-found') {
    notFound();
  }

  const next = getNextAfterLoginRoute();
  const loginSite = resolveLoginSite(allowed, options?.loginSite);
  if (loginSite === 'admin') {
    const target: AdminAfterLoginRoute =
      next === ADMIN_ROUTES.dashboard.href ? ADMIN_ROUTES.dashboard.href : ADMIN_ROUTES.dashboard.href;
    const loginRoute = buildAdminLoginRedirectRoute(target);
    redirect(loginRoute);
  }

  const loginRoute = buildPortalLoginRedirectRoute(next);
  redirect(loginRoute);
}
