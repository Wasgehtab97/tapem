import type { Route } from 'next';

export const ROUTES = {
  home: '/' as Route,
  gym: '/gym' as Route,
  gymMembers: '/gym/members' as Route,
  gymChallenges: '/gym/challenges' as Route,
  gymLeaderboard: '/gym/leaderboard' as Route,
  admin: '/admin' as Route,
  imprint: '/imprint' as Route,
  privacy: '/privacy' as Route,
} as const;

export type AppRoute = (typeof ROUTES)[keyof typeof ROUTES];

// Whitelist für Redirects nach Login:
export const ALLOWED_AFTER_LOGIN = [
  ROUTES.gym,
  ROUTES.gymMembers,
  ROUTES.gymChallenges,
  ROUTES.gymLeaderboard,
  ROUTES.admin,
] as const;
