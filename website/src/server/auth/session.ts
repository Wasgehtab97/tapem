import 'server-only';

import { cookies } from 'next/headers';
import type { DecodedIdToken } from 'firebase-admin/auth';

import { ADMIN_SESSION_COOKIE } from '@/src/lib/auth/constants';
import type { AuthenticatedUser, Role } from '@/src/lib/auth/types';
import { getFirebaseAdminAuth, getFirebaseAdminFirestore } from '@/src/server/firebase/admin';
import { ADMIN_SESSION_MAX_AGE_SECONDS } from '@/src/server/auth/cookies';

export class AdminRoleRequiredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AdminRoleRequiredError';
  }
}

type RoleResolution = {
  role: Role | null;
  source: 'claim' | 'profile' | 'allowlist' | 'unknown';
};

let cachedAdminAllowlist: string[] | null = null;

function readAllowlistEnv(): string | undefined {
  const keys = ['ADMIN_ALLOWED_EMAILS', 'ADMIN_ALLOWLIST'] as const;
  for (const key of keys) {
    const value = process.env[key];
    if (value && value.trim().length > 0) {
      return value;
    }
  }
  return undefined;
}

function getAdminAllowlist(): string[] {
  if (cachedAdminAllowlist) {
    return cachedAdminAllowlist;
  }

  const raw = readAllowlistEnv();
  if (!raw) {
    cachedAdminAllowlist = [];
    return cachedAdminAllowlist;
  }

  cachedAdminAllowlist = raw
    .split(',')
    .map((entry) => entry.trim().toLowerCase())
    .filter((entry) => entry.length > 0);

  return cachedAdminAllowlist;
}

function isEmailAllowlisted(email: string | null | undefined): boolean {
  if (!email) {
    return false;
  }

  const allowlist = getAdminAllowlist();
  if (allowlist.length === 0) {
    return false;
  }

  return allowlist.includes(email.trim().toLowerCase());
}

function extractRoleFromToken(token: DecodedIdToken): Role | null {
  const claim = (token.role ?? (token as Record<string, unknown>).role) as string | undefined;
  if (claim === 'admin' || claim === 'owner') {
    return claim as Role;
  }

  return null;
}

async function fetchRoleFromProfile(uid: string): Promise<Role | null> {
  try {
    const firestore = getFirebaseAdminFirestore();
    const userSnap = await firestore.collection('users').doc(uid).get();
    const userData = userSnap.data() as { role?: string } | undefined;
    const role = typeof userData?.role === 'string' ? (userData.role as Role) : null;
    if (role === 'admin' || role === 'owner') {
      return role;
    }
  } catch (error) {
    console.error('[auth] failed to resolve role from profile', error);
  }

  return null;
}

export async function isAdminUser(uid: string, email?: string | null): Promise<boolean> {
  if (isEmailAllowlisted(email ?? undefined)) {
    return true;
  }

  const role = await fetchRoleFromProfile(uid);
  return role === 'admin' || role === 'owner';
}

async function resolveRole(token: DecodedIdToken): Promise<RoleResolution> {
  const claimRole = extractRoleFromToken(token);
  if (claimRole) {
    return { role: claimRole, source: 'claim' };
  }

  if (isEmailAllowlisted(token.email)) {
    return { role: 'admin', source: 'allowlist' };
  }

  const profileRole = await fetchRoleFromProfile(token.uid);
  if (profileRole) {
    return { role: profileRole, source: 'profile' };
  }

  return { role: null, source: 'unknown' };
}

function buildAuthenticatedUser(
  token: DecodedIdToken,
  role: Role,
  source: 'claim' | 'profile' | 'allowlist'
): AuthenticatedUser {
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

function normalizeRoleSource(source: RoleResolution['source']): 'claim' | 'profile' | 'allowlist' {
  if (source === 'claim' || source === 'profile' || source === 'allowlist') {
    return source;
  }

  return 'profile';
}

export async function createAdminSession(idToken: string): Promise<{
  cookieValue: string;
  expiresIn: number;
  user: AuthenticatedUser;
}> {
  const auth = getFirebaseAdminAuth();
  const decoded = await auth.verifyIdToken(idToken, true);
  const { role, source } = await resolveRole(decoded);

  if (role !== 'admin' && role !== 'owner') {
    throw new AdminRoleRequiredError('Der angemeldete Nutzer besitzt keine Admin-Rolle.');
  }

  const expiresIn = ADMIN_SESSION_MAX_AGE_SECONDS * 1000;
  const cookieValue = await auth.createSessionCookie(idToken, { expiresIn });
  return {
    cookieValue,
    expiresIn,
    user: buildAuthenticatedUser(decoded, role, normalizeRoleSource(source)),
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
    if (role !== 'admin' && role !== 'owner') {
      return null;
    }

    return buildAuthenticatedUser(decoded, role, normalizeRoleSource(source));
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

