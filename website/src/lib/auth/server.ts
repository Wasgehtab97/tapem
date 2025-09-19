import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';

import {
  DEFAULT_AFTER_LOGIN,
  buildLoginRedirectRoute,
  isAllowedAfterLoginRoute,
  type AllowedAfterLoginRoute,
} from '@/src/lib/routes';

import type { DevUser, Role } from './types';

const ROLE_COOKIE = 'tapem_role';
const EMAIL_COOKIE = 'tapem_email';
const DEFAULT_EMAIL = 'anonymous@tapem.dev';
const ROLES: Role[] = ['admin', 'owner', 'operator'];

function normalizeCandidate(candidate: string | null): string | null {
  if (!candidate) {
    return null;
  }

  if (candidate.startsWith('/')) {
    const [pathname] = candidate.split('?');
    return pathname && pathname.length > 0 ? pathname : '/';
  }

  try {
    const url = new URL(candidate, 'http://localhost');
    return url.pathname || '/';
  } catch {
    return null;
  }
}

function getNextAfterLoginRoute(): AllowedAfterLoginRoute {
  const headerList = headers();
  const candidates = [
    headerList.get('x-next-url'),
    headerList.get('next-url'),
    headerList.get('referer'),
  ];

  for (const candidate of candidates) {
    const normalized = normalizeCandidate(candidate);
    if (normalized && isAllowedAfterLoginRoute(normalized)) {
      return normalized;
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

export async function requireRole(allowed: Role[]) {
  const user = getDevUserFromCookies();

  if (user && allowed.includes(user.role)) {
    return { user } as const;
  }

  const next = getNextAfterLoginRoute();
  const loginRoute = buildLoginRedirectRoute(next);
  redirect(loginRoute);
}
