import { NextResponse } from 'next/server';

const ROLE_COOKIE = 'tapem_role';
const EMAIL_COOKIE = 'tapem_email';

function isProduction() {
  return process.env.VERCEL_ENV === 'production';
}

export async function POST() {
  if (isProduction()) {
    return new NextResponse('dev login disabled in production', { status: 403 });
  }

  const response = new NextResponse(null, { status: 204 });
  const secure = process.env.NODE_ENV === 'production';

  response.cookies.set({
    name: ROLE_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 0,
    path: '/',
    secure,
  });

  response.cookies.set({
    name: EMAIL_COOKIE,
    value: '',
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 0,
    path: '/',
    secure,
  });

  return response;
}
