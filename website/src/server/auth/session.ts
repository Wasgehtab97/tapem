import 'server-only';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import type { AuthenticatedUser } from '@/src/lib/auth/types';
import { adminAuth } from '@/src/server/firebase/admin';
import { cookieOptions, SESSION_COOKIE_NAME } from './cookies';
import { resolveAdminRole } from './roles';

export async function getSession() {
  const c = cookies().get(SESSION_COOKIE_NAME)?.value;
  if (!c) return null;
  try {
    const decoded = await adminAuth().verifySessionCookie(c, true);
    return decoded; // enthält uid, email, claims, exp, ...
  } catch {
    return null;
  }
}

export function setSessionCookie(resp: NextResponse, sessionCookie: string) {
  const opts = cookieOptions();
  resp.cookies.set(opts.name, sessionCookie, opts);
  return resp;
}

export function clearSessionCookie(resp: NextResponse) {
  const opts = cookieOptions();
  resp.cookies.set(opts.name, '', { ...opts, maxAge: 0 });
  return resp;
}

export async function getAdminUserFromSession(): Promise<AuthenticatedUser | null> {
  const session = await getSession();
  if (!session) return null;
  const roleInfo = await resolveAdminRole(session.uid, (session as any).email ?? null);
  if (!roleInfo) return null;
  return {
    uid: session.uid,
    email: (session as any).email ?? session.uid,
    role: roleInfo.role,
    displayName: (session as any).name ?? null,
    source: 'firebase-session',
    claims: session as any,
    roleSource: roleInfo.source,
  };
}
