import type { Metadata } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import MarketingShell from '@/src/components/layout/marketing-shell';
import { buildSiteMetadata, getSiteConfig } from '@/src/config/sites';

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('marketing'), host);
}

export default function MarketingLayout({ children }: { children: ReactNode }) {
  return <MarketingShell>{children}</MarketingShell>;
}
