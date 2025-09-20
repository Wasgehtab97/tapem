import type { Metadata } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import AdminShell from '@/src/components/layout/admin-shell';
import { buildSiteMetadata, getSiteConfig } from '@/src/config/sites';

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('admin'), host);
}

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <AdminShell>{children}</AdminShell>;
}
