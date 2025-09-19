import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';

import type { DevUser, Role } from './types';

const ROLE_COOKIE = 'tapem_role';
const EMAIL_COOKIE = 'tapem_email';
const DEFAULT_EMAIL = 'anonymous@tapem.dev';
const ROLES: Role[] = ['admin', 'owner', 'operator'];

function getCurrentPath(): string {
  const headerList = headers();
  const candidates = [
    headerList.get('x-next-url'),
    headerList.get('next-url'),
    headerList.get('referer'),
  ];

  for (const candidate of candidates) {
    if (!candidate) {
      continue;
    }

    try {
      const url = new URL(candidate, 'http://localhost');
      const pathname = url.pathname || '/';
      const search = url.search ?? '';
      return `${pathname}${search}`;
    } catch {
      if (candidate.startsWith('/')) {
        return candidate;
      }
    }
  }

  return '/';
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

  const next = getCurrentPath();
  redirect(`/login?next=${encodeURIComponent(next)}`);
}
