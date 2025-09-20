import Link from 'next/link';
import { ReactNode } from 'react';

import { getDeploymentStage } from '@/src/config/sites';
import { ADMIN_ROUTES, MARKETING_ROUTES } from '@/src/lib/routes';
import { ThemeToggle } from '@/src/components/theme-toggle';

const marketingNav = [
  { label: 'Features', href: '/#features' },
  { label: "So funktioniert's", href: '/#how-it-works' },
  { label: 'FAQ', href: '/#faq' },
  { label: 'Kontakt', href: '/#contact' },
] as const;

export default function MarketingShell({ children }: { children: ReactNode }) {
  const stage = getDeploymentStage();
  const showPreviewLabel = stage !== 'production';

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-subtle surface-blur">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-6 px-6 py-4">
          <Link
            href={MARKETING_ROUTES.home.href}
            className="text-lg font-semibold text-page focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Tap&apos;em
          </Link>

          <nav className="hidden items-center gap-6 text-sm font-medium text-muted md:flex" aria-label="Marketing-Navigation">
            {marketingNav.map((item) => (
              <a key={item.href} className="transition hover:text-primary" href={item.href}>
                {item.label}
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-3">
            <Link
              href={ADMIN_ROUTES.login.href}
              className="rounded-full bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/30 transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              Für Studios: Login
            </Link>
            <ThemeToggle />
          </div>
        </div>
      </header>

      <main className="flex-1">{children}</main>

      <footer className="border-t border-subtle bg-surface-muted">
        <div className="mx-auto flex w-full max-w-6xl flex-col items-center gap-2 px-6 py-6 text-sm text-muted md:flex-row md:justify-between">
          <p>
            © {new Date().getFullYear()} Tap&apos;em{showPreviewLabel ? ' – Preview' : ''}
          </p>
          <nav aria-label="Footer-Navigation" className="flex items-center gap-4">
            <Link
              href={MARKETING_ROUTES.imprint.href}
              className="transition hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              Impressum
            </Link>
            <Link
              href={MARKETING_ROUTES.privacy.href}
              className="transition hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              Datenschutz
            </Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
