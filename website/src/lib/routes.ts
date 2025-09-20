import type { Route } from 'next';

import type { SiteKey } from '@/src/config/sites';

type RouteDefinition<Site extends SiteKey, Path extends Route> = {
  readonly site: Site;
  readonly href: Path;
  readonly pathname: Path;
};

function defineRoute<Site extends SiteKey, Path extends Route>(
  site: Site,
  pathname: Path
): RouteDefinition<Site, Path> {
  return {
    site,
    href: pathname,
    pathname,
  } as const;
}

export const MARKETING_ROUTES = {
  home: defineRoute('marketing', '/' as Route),
  imprint: defineRoute('marketing', '/imprint' as Route),
  privacy: defineRoute('marketing', '/privacy' as Route),
} as const;

export type MarketingRouteDefinition =
  (typeof MARKETING_ROUTES)[keyof typeof MARKETING_ROUTES];
export type MarketingRoute = MarketingRouteDefinition['href'];

const MARKETING_ROUTE_LIST = Object.values(
  MARKETING_ROUTES
) as readonly MarketingRouteDefinition[];

export const PORTAL_ROUTES = {
  home: defineRoute('portal', '/' as Route),
  login: defineRoute('portal', '/login' as Route),
  gym: defineRoute('portal', '/gym' as Route),
  gymMembers: defineRoute('portal', '/gym/members' as Route),
  gymChallenges: defineRoute('portal', '/gym/challenges' as Route),
  gymLeaderboard: defineRoute('portal', '/gym/leaderboard' as Route),
} as const;

export type PortalRouteDefinition =
  (typeof PORTAL_ROUTES)[keyof typeof PORTAL_ROUTES];
export type PortalRoute = PortalRouteDefinition['href'];

const PORTAL_ROUTE_LIST = Object.values(
  PORTAL_ROUTES
) as readonly PortalRouteDefinition[];

export const ADMIN_ROUTES = {
  dashboard: defineRoute('admin', '/admin' as Route),
  login: defineRoute('admin', '/admin/login' as Route),
  logout: defineRoute('admin', '/admin/logout' as Route),
} as const;

export type AdminRouteDefinition =
  (typeof ADMIN_ROUTES)[keyof typeof ADMIN_ROUTES];
export type AdminRoute = AdminRouteDefinition['href'];

const ADMIN_ROUTE_LIST = Object.values(
  ADMIN_ROUTES
) as readonly AdminRouteDefinition[];

export type AppRouteDefinition =
  | MarketingRouteDefinition
  | PortalRouteDefinition
  | AdminRouteDefinition;
export type AppRoute = AppRouteDefinition['href'];

const APP_ROUTE_LIST: readonly AppRouteDefinition[] = [
  ...MARKETING_ROUTE_LIST,
  ...PORTAL_ROUTE_LIST,
  ...ADMIN_ROUTE_LIST,
];

const APP_ROUTE_SET = new Set<AppRoute>(
  APP_ROUTE_LIST.map((route) => route.href)
);

export function findRouteDefinition(
  pathname: string,
  site?: SiteKey
): AppRouteDefinition | null {
  const normalized = normalizePathname(pathname);
  if (site) {
    return (
      APP_ROUTE_LIST.find(
        (route) => route.href === normalized && route.site === site
      ) ?? null
    );
  }
  return APP_ROUTE_LIST.find((route) => route.href === normalized) ?? null;
}

const SHARED_ERROR_PATHS = ['/401', '/403', '/404'] as const;
const SHARED_UTILITY_PATHS = ['/robots.txt', '/sitemap.xml'] as const;
const SHARED_MARKETING_ASSETS = ['/opengraph-image'] as const;

function buildPathSet(paths: readonly string[]): Set<string> {
  return new Set(paths.map((path) => normalizePathname(path)));
}

const MARKETING_ALLOWED_PATHS = buildPathSet([
  ...MARKETING_ROUTE_LIST.map((route) => route.href),
  ...SHARED_ERROR_PATHS,
  ...SHARED_UTILITY_PATHS,
  ...SHARED_MARKETING_ASSETS,
]);

const PORTAL_PUBLIC_PATHS = buildPathSet([
  PORTAL_ROUTES.login.href,
  ...SHARED_ERROR_PATHS,
  ...SHARED_UTILITY_PATHS,
]);

const PORTAL_PROTECTED_PATHS = buildPathSet([
  PORTAL_ROUTES.home.href,
  PORTAL_ROUTES.gym.href,
  PORTAL_ROUTES.gymMembers.href,
  PORTAL_ROUTES.gymChallenges.href,
  PORTAL_ROUTES.gymLeaderboard.href,
]);

const ADMIN_PUBLIC_PATHS = buildPathSet([
  ADMIN_ROUTES.login.href,
  ADMIN_ROUTES.logout.href,
  ...SHARED_ERROR_PATHS,
  ...SHARED_UTILITY_PATHS,
]);

const ADMIN_PROTECTED_PATHS = buildPathSet([
  ADMIN_ROUTES.dashboard.href,
]);

export const AFTER_LOGIN_ROUTES = [
  PORTAL_ROUTES.gym,
  PORTAL_ROUTES.gymMembers,
  PORTAL_ROUTES.gymChallenges,
  PORTAL_ROUTES.gymLeaderboard,
  ADMIN_ROUTES.dashboard,
] as const;

export type AfterLoginRouteDefinition =
  (typeof AFTER_LOGIN_ROUTES)[number];
export type AfterLoginRoute = AfterLoginRouteDefinition['href'];

const AFTER_LOGIN_ROUTE_SET = new Set<AfterLoginRoute>(
  AFTER_LOGIN_ROUTES.map((route) => route.href)
);

export const DEFAULT_AFTER_LOGIN_ROUTE = PORTAL_ROUTES.gym;
export const DEFAULT_AFTER_LOGIN: AfterLoginRoute =
  DEFAULT_AFTER_LOGIN_ROUTE.href;

function normalizeRouteCandidate(
  value: string | null | undefined
): string | null {
  if (!value) {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  if (trimmed.startsWith('//')) {
    return null;
  }

  if (trimmed.startsWith('/')) {
    const [pathname] = trimmed.split('?');
    return normalizePathname(pathname || '/');
  }

  try {
    const url = new URL(trimmed, 'http://localhost');
    return normalizePathname(url.pathname || '/');
  } catch {
    return null;
  }
}

type SafeNextRouteOptions<TRoute extends AppRouteDefinition> = {
  readonly allow: readonly TRoute[];
  readonly fallback: TRoute;
};

export function safeNextRoute<TRoute extends AppRouteDefinition>(
  candidate: string | null | undefined,
  options: SafeNextRouteOptions<TRoute>
): TRoute {
  const normalized = normalizeRouteCandidate(candidate);
  if (!normalized) {
    return options.fallback;
  }

  const match = options.allow.find((route) => route.href === normalized);
  return match ?? options.fallback;
}

export function safeNextPath<TRoute extends AppRouteDefinition>(
  candidate: string | null | undefined,
  options: SafeNextRouteOptions<TRoute>
): TRoute['href'] {
  return safeNextRoute(candidate, options).href;
}

export function isAfterLoginRoute(
  value: string | null | undefined
): value is AfterLoginRoute {
  const normalized = normalizeRouteCandidate(value);
  if (!normalized) {
    return false;
  }
  return AFTER_LOGIN_ROUTE_SET.has(normalized as AfterLoginRoute);
}

export function safeAfterLoginRoute(
  value: string | null | undefined
): AfterLoginRoute {
  return safeNextPath(value, {
    allow: AFTER_LOGIN_ROUTES,
    fallback: DEFAULT_AFTER_LOGIN_ROUTE,
  });
}

export function buildPortalLoginRedirectRoute(target: AfterLoginRoute): Route {
  return `${PORTAL_ROUTES.login.href}?next=${target}` as Route;
}

type AdminAfterLoginRouteDefinition = typeof ADMIN_ROUTES.dashboard;
export type AdminAfterLoginRoute = AdminAfterLoginRouteDefinition['href'];

export function buildAdminLoginRedirectRoute(target: AdminAfterLoginRoute): Route {
  return `${ADMIN_ROUTES.login.href}?next=${target}` as Route;
}

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
  return (
    PORTAL_PUBLIC_PATHS.has(normalized) ||
    PORTAL_PROTECTED_PATHS.has(normalized)
  );
}

export function isPortalProtectedPath(pathname: string): boolean {
  return PORTAL_PROTECTED_PATHS.has(normalizePathname(pathname));
}

export function isAdminPath(pathname: string): boolean {
  const normalized = normalizePathname(pathname);
  return (
    ADMIN_PUBLIC_PATHS.has(normalized) ||
    ADMIN_PROTECTED_PATHS.has(normalized)
  );
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

export function isAppRoute(
  value: string | null | undefined
): value is AppRoute {
  if (!value) {
    return false;
  }
  const normalized = normalizeRouteCandidate(value);
  if (!normalized) {
    return false;
  }
  return APP_ROUTE_SET.has(normalized as AppRoute);
}
