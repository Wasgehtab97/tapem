import Link from 'next/link';
import { ReactNode } from 'react';

import { getDeploymentStage } from '@/src/config/sites';
import DevToolbar from '@/src/components/dev-toolbar';
import { getDevUserFromCookies } from '@/src/lib/auth/server';
import type { Role } from '@/src/lib/auth/types';
import { ADMIN_ROUTES } from '@/src/lib/routes';

export default function AdminShell({ children }: { children: ReactNode }) {
  const stage = getDeploymentStage();
  const isProduction = stage === 'production';
  const devUser = isProduction ? null : getDevUserFromCookies();
  const currentRole: Role | null = devUser?.role ?? null;

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-subtle bg-surface">
        <div className="mx-auto flex w-full max-w-5xl items-center justify-between gap-4 px-6 py-3">
          <Link
            href={ADMIN_ROUTES.dashboard}
            className="text-base font-semibold text-page focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Tap&apos;em Admin
          </Link>
          {isProduction ? <div className="hidden" aria-hidden /> : <DevToolbar currentRole={currentRole} />}
        </div>
      </header>

      <main className="flex-1 bg-page">{children}</main>

      <footer className="border-t border-subtle bg-surface-muted">
        <div className="mx-auto w-full max-w-5xl px-6 py-3 text-xs text-muted">
          Interner Monitoring-Bereich · {new Date().getFullYear()}
        </div>
      </footer>
    </div>
  );
}
