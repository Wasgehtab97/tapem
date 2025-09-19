import 'server-only';

import { cookies } from 'next/headers';
import type { DecodedIdToken } from 'firebase-admin/auth';

import type { AuthenticatedUser, Role } from '@/src/lib/auth/types';
import { getFirebaseAdminAuth, getFirebaseAdminFirestore } from '@/src/server/firebase/admin';

export const ADMIN_SESSION_COOKIE = '__Secure-tapem-admin-session';
export const ADMIN_SESSION_MAX_AGE_SECONDS = 60 * 60 * 24 * 5; // 5 Tage

export class AdminRoleRequiredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AdminRoleRequiredError';
  }
}

type RoleResolution = {
  role: Role | null;
  source: 'claim' | 'profile' | 'unknown';
};

function extractRoleFromToken(token: DecodedIdToken): Role | null {
  const claim = (token.role ?? (token as Record<string, unknown>).role) as string | undefined;
  if (claim === 'admin') {
    return 'admin';
  }

  return null;
}

async function resolveRole(token: DecodedIdToken): Promise<RoleResolution> {
  const claimRole = extractRoleFromToken(token);
  if (claimRole) {
    return { role: claimRole, source: 'claim' };
  }

  const uid = token.uid;
  try {
    const firestore = getFirebaseAdminFirestore();
    const userSnap = await firestore.collection('users').doc(uid).get();
    const userData = userSnap.data() as { role?: string } | undefined;
    if (userData?.role === 'admin') {
      return { role: 'admin', source: 'profile' };
    }
  } catch (error) {
    console.error('[auth] failed to resolve role from profile', error);
  }

  return { role: null, source: 'unknown' };
}

function buildAuthenticatedUser(token: DecodedIdToken, role: Role, source: 'claim' | 'profile'): AuthenticatedUser {
  return {
    uid: token.uid,
    email: token.email ?? token.uid,
    role,
    displayName: token.name ?? null,
    source: 'firebase-session',
    claims: token,
    roleSource: source,
  };
}

export async function createAdminSession(idToken: string): Promise<{
  cookieValue: string;
  expiresIn: number;
  user: AuthenticatedUser;
}> {
  const auth = getFirebaseAdminAuth();
  const decoded = await auth.verifyIdToken(idToken, true);
  const { role, source } = await resolveRole(decoded);

  if (role !== 'admin') {
    throw new AdminRoleRequiredError('Der angemeldete Nutzer besitzt keine Admin-Rolle.');
  }

  const expiresIn = ADMIN_SESSION_MAX_AGE_SECONDS * 1000;
  const cookieValue = await auth.createSessionCookie(idToken, { expiresIn });
  return {
    cookieValue,
    expiresIn,
    user: buildAuthenticatedUser(decoded, role, source === 'claim' ? 'claim' : 'profile'),
  };
}

export async function verifyAdminSessionCookie(cookieValue: string): Promise<AuthenticatedUser | null> {
  if (!cookieValue || cookieValue.length === 0) {
    return null;
  }

  try {
    const auth = getFirebaseAdminAuth();
    const decoded = await auth.verifySessionCookie(cookieValue, true);
    const { role, source } = await resolveRole(decoded);
    if (role !== 'admin') {
      return null;
    }

    return buildAuthenticatedUser(decoded, role, source === 'claim' ? 'claim' : 'profile');
  } catch (error) {
    console.error('[auth] failed to verify admin session cookie', error);
    return null;
  }
}

export async function getAdminUserFromSession(): Promise<AuthenticatedUser | null> {
  const cookieStore = cookies();
  const sessionCookie = cookieStore.get(ADMIN_SESSION_COOKIE)?.value;
  if (!sessionCookie) {
    return null;
  }

  return verifyAdminSessionCookie(sessionCookie);
}

export async function revokeAdminSessionCookie(cookieValue: string | null | undefined): Promise<void> {
  if (!cookieValue) {
    return;
  }

  try {
    const auth = getFirebaseAdminAuth();
    const decoded = await auth.verifySessionCookie(cookieValue, false);
    await auth.revokeRefreshTokens(decoded.sub ?? decoded.uid);
  } catch (error) {
    console.error('[auth] unable to revoke admin session', error);
  }
}
