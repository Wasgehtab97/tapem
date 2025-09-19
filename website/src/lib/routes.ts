import type { Route } from 'next';

import type { SiteKey } from '@/src/config/sites';

export const MARKETING_ROUTES = {
  home: '/' as Route,
  imprint: '/imprint' as Route,
  privacy: '/privacy' as Route,
} as const satisfies Record<string, Route>;

export const PORTAL_ROUTES = {
  home: '/' as Route,
  login: '/login' as Route,
  gym: '/gym' as Route,
  gymMembers: '/gym/members' as Route,
  gymChallenges: '/gym/challenges' as Route,
  gymLeaderboard: '/gym/leaderboard' as Route,
} as const satisfies Record<string, Route>;

export const ADMIN_ROUTES = {
  home: '/' as Route,
  dashboard: '/admin' as Route,
} as const satisfies Record<string, Route>;

export type AllowedAfterLoginRoute =
  | typeof PORTAL_ROUTES.gym
  | typeof PORTAL_ROUTES.gymMembers
  | typeof PORTAL_ROUTES.gymChallenges
  | typeof PORTAL_ROUTES.gymLeaderboard
  | typeof ADMIN_ROUTES.dashboard;

export const ALLOWED_AFTER_LOGIN: ReadonlyArray<AllowedAfterLoginRoute> = [
  PORTAL_ROUTES.gym,
  PORTAL_ROUTES.gymMembers,
  PORTAL_ROUTES.gymChallenges,
  PORTAL_ROUTES.gymLeaderboard,
  ADMIN_ROUTES.dashboard,
];

export const DEFAULT_AFTER_LOGIN: AllowedAfterLoginRoute = PORTAL_ROUTES.gym;

export type LoginRedirectRoute = `/login?next=${AllowedAfterLoginRoute}`;

export function isAllowedAfterLoginRoute(
  value: string | null | undefined
): value is AllowedAfterLoginRoute {
  if (typeof value !== 'string') {
    return false;
  }

  return (ALLOWED_AFTER_LOGIN as readonly string[]).some((route) => route === value);
}

export function resolveAllowedAfterLoginRoute(
  value: string | null | undefined
): AllowedAfterLoginRoute {
  return isAllowedAfterLoginRoute(value) ? value : DEFAULT_AFTER_LOGIN;
}

export function buildLoginRedirectRoute(target: AllowedAfterLoginRoute): Route {
  return `/login?next=${target}` as Route;
}

const MARKETING_ALLOWED_PATHS = new Set<string>([
  MARKETING_ROUTES.home,
  MARKETING_ROUTES.imprint,
  MARKETING_ROUTES.privacy,
  '/401',
  '/403',
  '/404',
  '/opengraph-image',
  '/robots.txt',
  '/sitemap.xml',
]);

const PORTAL_PUBLIC_PATHS = new Set<string>([
  PORTAL_ROUTES.login,
  '/401',
  '/403',
  '/404',
  '/robots.txt',
  '/sitemap.xml',
]);

const PORTAL_PROTECTED_PATHS = new Set<string>([
  PORTAL_ROUTES.home,
  PORTAL_ROUTES.gym,
  PORTAL_ROUTES.gymMembers,
  PORTAL_ROUTES.gymChallenges,
  PORTAL_ROUTES.gymLeaderboard,
]);

const ADMIN_PUBLIC_PATHS = new Set<string>(['/401', '/403', '/404', '/robots.txt', '/sitemap.xml']);

const ADMIN_PROTECTED_PATHS = new Set<string>([
  ADMIN_ROUTES.home,
  ADMIN_ROUTES.dashboard,
]);

export function normalizePathname(pathname: string): string {
  if (!pathname) {
    return '/';
  }
  if (pathname === '/') {
    return pathname;
  }
  return pathname.endsWith('/') ? pathname.slice(0, -1) : pathname;
}

export function isMarketingPath(pathname: string): boolean {
  return MARKETING_ALLOWED_PATHS.has(normalizePathname(pathname));
}

export function isPortalPath(pathname: string): boolean {
  const normalized = normalizePathname(pathname);
  return PORTAL_PUBLIC_PATHS.has(normalized) || PORTAL_PROTECTED_PATHS.has(normalized);
}

export function isPortalProtectedPath(pathname: string): boolean {
  return PORTAL_PROTECTED_PATHS.has(normalizePathname(pathname));
}

export function isAdminPath(pathname: string): boolean {
  const normalized = normalizePathname(pathname);
  return ADMIN_PUBLIC_PATHS.has(normalized) || ADMIN_PROTECTED_PATHS.has(normalized);
}

export function isAdminProtectedPath(pathname: string): boolean {
  return ADMIN_PROTECTED_PATHS.has(normalizePathname(pathname));
}

export function isRouteAllowedOnSite(pathname: string, site: SiteKey): boolean {
  if (site === 'marketing') {
    return isMarketingPath(pathname);
  }
  if (site === 'portal') {
    return isPortalPath(pathname);
  }
  return isAdminPath(pathname);
}
