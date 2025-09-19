import type { Metadata } from 'next';
import { ReactNode } from 'react';

import GymSubnav from '@/src/components/gym-subnav';

export const metadata: Metadata = {
  robots: {
    index: false,
    follow: false,
  },
};

export default function GymLayout({ children }: { children: ReactNode }) {
  return (
    <div className="mx-auto w-full max-w-6xl space-y-8 px-6 py-16">
      <div className="rounded-lg border border-subtle bg-card p-4 shadow-sm">
        <GymSubnav />
      </div>
      <div className="space-y-10">{children}</div>
    </div>
  );
}
