'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { Route } from 'next';
import { ROUTES } from '@/src/lib/routes';

const items = [
  { href: ROUTES.gym, label: 'Übersicht' },
  { href: ROUTES.gymMembers, label: 'Mitglieder' },
  { href: ROUTES.gymChallenges, label: 'Challenges' },
  { href: ROUTES.gymLeaderboard, label: 'Rangliste' },
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
              'rounded-full border px-4 py-2 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900 ' +
              (isActive
                ? 'border-slate-900 bg-slate-900 text-white'
                : 'border-slate-300 text-slate-700 hover:bg-slate-100')
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
