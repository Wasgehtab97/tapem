import type { Route } from 'next';

export const ROUTES = {
  home: '/' as Route,
  login: '/login' as Route,
  gym: '/gym' as Route,
  gymMembers: '/gym/members' as Route,
  gymChallenges: '/gym/challenges' as Route,
  gymLeaderboard: '/gym/leaderboard' as Route,
  admin: '/admin' as Route,
  imprint: '/imprint' as Route,
  privacy: '/privacy' as Route,
} as const satisfies Record<string, Route>;

export type AppRoute = (typeof ROUTES)[keyof typeof ROUTES];

export const ALLOWED_AFTER_LOGIN = [
  ROUTES.gym,
  ROUTES.gymMembers,
  ROUTES.gymChallenges,
  ROUTES.gymLeaderboard,
  ROUTES.admin,
] as const satisfies ReadonlyArray<Route>;

export type AllowedAfterLoginRoute = (typeof ALLOWED_AFTER_LOGIN)[number];

export const DEFAULT_AFTER_LOGIN: AllowedAfterLoginRoute = ROUTES.gym;

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

export type LoginRedirectRoute = `/login?next=${AllowedAfterLoginRoute}`;

export function buildLoginRedirectRoute(target: AllowedAfterLoginRoute): Route {
  return `/login?next=${target}` as Route;
}
