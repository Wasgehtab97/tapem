import 'server-only';

import { getDeploymentStage, getSiteConfig, normalizeHost } from '@/src/config/sites';

function isLocalHost(hostname: string): boolean {
  return hostname.includes('localhost') || hostname.startsWith('127.');
}

function stripPort(hostname: string): string {
  return hostname.includes(':') ? hostname.split(':')[0] : hostname;
}

export function resolveCookieDomain(request: Request): string | undefined {
  const hostHeader = request.headers.get('host');
  const normalized = normalizeHost(hostHeader);
  if (!normalized) {
    return undefined;
  }

  const hostname = stripPort(normalized);
  if (!hostname || isLocalHost(hostname)) {
    return undefined;
  }

  const stage = getDeploymentStage();
  if (stage === 'development') {
    return undefined;
  }

  const marketing = getSiteConfig('marketing');
  const candidate =
    stage === 'production'
      ? marketing.hosts.production
      : marketing.hosts.preview[0] ?? marketing.hosts.production;

  if (!candidate) {
    return hostname;
  }

  const target = stripPort(candidate);
  if (!target || isLocalHost(target)) {
    return hostname;
  }

  const matchesHost = hostname === target || hostname.endsWith(`.${target}`);
  if (!matchesHost) {
    return hostname;
  }

  return target;
}

export function resolveCookieSecurity(): boolean {
  return process.env.NODE_ENV === 'production';
}
