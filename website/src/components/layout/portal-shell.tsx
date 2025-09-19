import Link from 'next/link';
import { ReactNode } from 'react';

import { getDeploymentStage } from '@/src/config/sites';
import DevToolbar from '@/src/components/dev-toolbar';
import { getDevUserFromCookies } from '@/src/lib/auth/server';
import type { Role } from '@/src/lib/auth/types';
import { PORTAL_ROUTES, type PortalRouteDefinition } from '@/src/lib/routes';

const portalNav = [
  { route: PORTAL_ROUTES.gym, label: 'Dashboard' },
  { route: PORTAL_ROUTES.gymMembers, label: 'Mitglieder' },
  { route: PORTAL_ROUTES.gymChallenges, label: 'Challenges' },
  { route: PORTAL_ROUTES.gymLeaderboard, label: 'Rangliste' },
] satisfies ReadonlyArray<{ route: PortalRouteDefinition; label: string }>;

export default function PortalShell({ children }: { children: ReactNode }) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';
  const devUser = isProduction ? null : getDevUserFromCookies();
  const currentRole: Role | null = devUser?.role ?? null;

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-subtle bg-surface">
        <div className="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-4 px-6 py-4">
          <Link
            href={PORTAL_ROUTES.gym.href}
            className="text-base font-semibold text-page focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Tap&apos;em Portal
          </Link>

          <nav className="flex items-center gap-4 text-sm font-medium text-muted" aria-label="Portal-Navigation">
            {portalNav.map((item) => (
              <Link
                key={item.route.href}
                href={item.route.href}
                className="rounded px-2 py-1 transition hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >
                {item.label}
              </Link>
            ))}
          </nav>

          {isProduction ? <div className="hidden" aria-hidden /> : <DevToolbar currentRole={currentRole} />}
        </div>
      </header>

      <main className="flex-1 bg-page">{children}</main>

      <footer className="border-t border-subtle bg-surface-muted">
        <div className="mx-auto w-full max-w-6xl px-6 py-4 text-sm text-muted">
          Tap&apos;em Studio-Portal · Geschützter Bereich · {new Date().getFullYear()}
        </div>
      </footer>
    </div>
  );
}
