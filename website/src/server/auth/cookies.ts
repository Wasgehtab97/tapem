import { getDeploymentStage, getSiteConfig, normalizeHost } from '@/config/sites';

export const ADMIN_SESSION_MAX_AGE_SECONDS = 60 * 60 * 24 * 7; // 7 Tage

export const ADMIN_SESSION_COOKIE_NAME =
  process.env.NODE_ENV === 'production' ? '__Secure-tapem-admin-session' : 'tapem-admin-session';

type CookieInit = {
  name: string;
  value: string;
  httpOnly: boolean;
  sameSite: 'lax' | 'strict' | 'none';
  secure: boolean;
  maxAge: number;
  path: string;
  domain?: string;
};

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

export function buildAdminSessionCookie(
  request: Request,
  value: string,
  maxAge: number = ADMIN_SESSION_MAX_AGE_SECONDS
): CookieInit {
  const secure = resolveCookieSecurity();
  const domain = resolveCookieDomain(request);
  return {
    name: ADMIN_SESSION_COOKIE_NAME,
    value,
    httpOnly: true,
    sameSite: 'lax',
    secure,
    maxAge,
    path: '/',
    domain,
  };
}
