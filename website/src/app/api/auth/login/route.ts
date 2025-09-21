import { NextResponse } from 'next/server';
import { adminAuth } from '@/src/server/firebase/admin';
import { setSessionCookie } from '@/src/server/auth/session';
import { isAdmin } from '@/src/server/auth/roles';
import { SESSION_MAX_AGE_SEC } from '@/src/server/auth/cookies';

export const runtime = 'nodejs';

export async function POST(req: Request) {
  try {
    const { idToken } = await req.json();
    if (!idToken) return NextResponse.json({ error: 'missing-idToken' }, { status: 400 });

    const decoded = await adminAuth().verifyIdToken(idToken, true);
    // Gate: nur Admins/Owner
    const ok = await isAdmin(decoded.uid, decoded.email ?? null);
    if (!ok) return NextResponse.json({ error: 'not-admin' }, { status: 403 });

    const sessionCookie = await adminAuth().createSessionCookie(idToken, { expiresIn: SESSION_MAX_AGE_SEC * 1000 });
    const resp = new NextResponse(null, { status: 204 });
    setSessionCookie(resp, sessionCookie);
    return resp;
  } catch (e: any) {
    return NextResponse.json({ error: String(e?.message ?? e) }, { status: 401 });
  }
}
