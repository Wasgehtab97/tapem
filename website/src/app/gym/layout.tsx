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
    <div className="space-y-8">
      <div className="rounded-lg border border-slate-200 bg-slate-50/60 p-4">
        <GymSubnav />
      </div>
      <div className="space-y-10">{children}</div>
    </div>
  );
}
