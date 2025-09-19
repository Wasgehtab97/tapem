'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/gym', label: 'Übersicht' },
  { href: '/gym/members', label: 'Mitglieder' },
  { href: '/gym/challenges', label: 'Challenges' },
  { href: '/gym/leaderboard', label: 'Leaderboard' },
];

export default function GymSubnav() {
  const pathname = usePathname();

  return (
    <nav aria-label="Gym Navigation" className="flex flex-wrap gap-2 text-sm font-medium text-slate-700">
      {navItems.map((item) => {
        const isActive = pathname === item.href;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={
              'rounded-full border px-4 py-2 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900 ' +
              (isActive
                ? 'border-slate-900 bg-slate-900 text-white'
                : 'border-slate-200 bg-white text-slate-700 hover:border-slate-900/60 hover:bg-slate-100')
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
