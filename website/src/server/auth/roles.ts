import 'server-only';
import { adminAuth } from '@/src/server/firebase/admin';

export type AdminRole = 'admin' | 'owner';
export type AdminRoleResolution = { role: AdminRole; source: 'allowlist' | 'claim' };

function parseAllowlist() {
  const raw = process.env.ADMIN_ALLOWED_EMAILS ?? process.env.ADMIN_ALLOWLIST; // fallback
  return raw ? raw.split(',').map(s => s.trim().toLowerCase()).filter(Boolean) : [];
}

export async function resolveAdminRole(uid: string, email?: string | null): Promise<AdminRoleResolution | null> {
  const allow = parseAllowlist();
  if (email && allow.includes(email.toLowerCase())) return { role: 'admin', source: 'allowlist' };

  try {
    const user = await adminAuth().getUser(uid);
    const role = (user.customClaims as any)?.role;
    if (role === 'admin' || role === 'owner') return { role, source: 'claim' };
  } catch {
    // ignore
  }

  return null;
}

export async function isAdmin(uid: string, email?: string | null) {
  return (await resolveAdminRole(uid, email)) !== null;
}
