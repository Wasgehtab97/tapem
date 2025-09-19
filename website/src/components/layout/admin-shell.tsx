import Link from 'next/link';
import { ReactNode } from 'react';

import DevToolbar from '@/src/components/dev-toolbar';
import { getDeploymentStage } from '@/src/config/sites';
import { getDevUserFromCookies } from '@/src/lib/auth/server';
import type { AuthenticatedUser, Role } from '@/src/lib/auth/types';
import { ADMIN_ROUTES, type AdminRouteDefinition } from '@/src/lib/routes';
import { getAdminUserFromSession } from '@/src/server/auth/session';

type NavigationItem = {
  label: string;
  route?: AdminRouteDefinition;
  disabled?: boolean;
};

const NAVIGATION: NavigationItem[] = [
  { label: 'Dashboard', route: ADMIN_ROUTES.dashboard },
  { label: 'KPIs & Analysen', disabled: true },
  { label: 'Geräteverwaltung', disabled: true },
  { label: 'Challenges', disabled: true },
  { label: 'Event-Logs', disabled: true },
];

function NavigationMenu({ items }: { items: NavigationItem[] }) {
  return (
    <nav aria-label="Admin Navigation" className="space-y-1">
      {items.map((item) => {
        if (item.disabled || !item.route) {
          return (
            <span
              key={item.label}
              className="block rounded-md px-3 py-2 text-sm text-slate-400"
              aria-disabled="true"
            >
              {item.label}
            </span>
          );
        }

        return (
          <Link
            key={item.label}
            href={item.route.href}
            className="block rounded-md px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}

function AdminHeader({
  user,
  devRole,
  isProduction,
}: {
  user: AuthenticatedUser | null;
  devRole: Role | null;
  isProduction: boolean;
}) {
  const showDevToolbar = !isProduction;

  return (
    <header className="border-b border-subtle bg-surface">
      <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-6 py-4">
        <Link
          href={ADMIN_ROUTES.dashboard.href}
          className="text-base font-semibold text-page focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
        >
          Tap&apos;em Admin
        </Link>
        <div className="flex items-center gap-4">
          {user ? (
            <div className="text-right">
              <p className="text-sm font-semibold text-slate-900">{user.email}</p>
              <p className="text-xs text-slate-500">Rolle: {user.role}</p>
            </div>
          ) : devRole ? (
            <div className="text-right">
              <p className="text-sm font-semibold text-slate-900">Dev-Rolle: {devRole}</p>
              <p className="text-xs text-slate-500">Nur Vorschau</p>
            </div>
          ) : null}
          {user ? (
            <Link
              href={ADMIN_ROUTES.logout.href}
              className="rounded-md border border-subtle px-3 py-1 text-sm font-semibold text-slate-700 transition hover:border-primary hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              Abmelden
            </Link>
          ) : null}
          {showDevToolbar ? <DevToolbar currentRole={devRole} /> : null}
        </div>
      </div>
    </header>
  );
}

export default async function AdminShell({ children }: { children: ReactNode }) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';
  const sessionUser = await getAdminUserFromSession();
  const devUser = isProduction ? null : getDevUserFromCookies();
  const devRole: Role | null = devUser?.role ?? null;
  const hasAdminAccess = Boolean(sessionUser) || devRole === 'admin';

  const header = <AdminHeader user={sessionUser} devRole={devRole} isProduction={isProduction} />;

  if (!hasAdminAccess) {
    return (
      <div className="flex min-h-screen flex-col bg-page">
        {header}
        <main className="flex-1 bg-page">{children}</main>
        <footer className="border-t border-subtle bg-surface-muted">
          <div className="mx-auto w-full max-w-6xl px-6 py-3 text-xs text-muted">
            Interner Monitoring-Bereich · {new Date().getFullYear()}
          </div>
        </footer>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-page">
      <aside className="hidden w-64 border-r border-subtle bg-surface px-4 py-6 lg:block">
        <NavigationMenu items={NAVIGATION} />
      </aside>
      <div className="flex min-h-screen flex-1 flex-col">
        {header}
        <main className="flex-1 bg-page">{children}</main>
        <footer className="border-t border-subtle bg-surface-muted">
          <div className="mx-auto w-full max-w-6xl px-6 py-3 text-xs text-muted">
            Interner Monitoring-Bereich · {new Date().getFullYear()}
          </div>
        </footer>
      </div>
    </div>
  );
}
