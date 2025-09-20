const isProductionEnv = process.env.NODE_ENV === 'production';

export const ADMIN_SESSION_COOKIE = isProductionEnv
  ? '__Secure-tapem-admin-session'
  : 'tapem-admin-session';

export const DEV_ROLE_COOKIE = 'tapem_role';
