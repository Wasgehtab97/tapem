'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { Route } from 'next';
import { PORTAL_ROUTES } from '@/src/lib/routes';

const items = [
  { href: PORTAL_ROUTES.gym, label: 'Übersicht' },
  { href: PORTAL_ROUTES.gymMembers, label: 'Mitglieder' },
  { href: PORTAL_ROUTES.gymChallenges, label: 'Challenges' },
  { href: PORTAL_ROUTES.gymLeaderboard, label: 'Rangliste' },
] satisfies ReadonlyArray<{ href: Route; label: string }>;

export default function GymSubnav() {
  const pathname = usePathname();

  return (
    <nav aria-label="Gym-Untermenü" className="flex flex-wrap gap-2">
      {items.map((item) => {
        const isActive = pathname === item.href;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={
              'rounded-full border px-4 py-2 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ' +
              (isActive
                ? 'border-primary bg-primary text-primary-foreground shadow-sm'
                : 'border-subtle text-muted hover:bg-card')
            }
            aria-current={isActive ? 'page' : undefined}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
