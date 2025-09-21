export const SESSION_COOKIE_NAME = 'tapem_session';
export const SESSION_MAX_AGE_SEC = 60 * 60 * 24 * 7; // 7 Tage

export function cookieOptions() {
  const prod = process.env.NODE_ENV === 'production';
  return {
    name: SESSION_COOKIE_NAME,
    httpOnly: true,
    sameSite: 'lax' as const,
    secure: prod, // in DEV nicht erzwingen
    path: '/',
    maxAge: SESSION_MAX_AGE_SEC,
  };
}
