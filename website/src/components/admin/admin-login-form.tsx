'use client';

import { useState, useTransition } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';

import {
  FirebaseClientConfigError,
  getFirebaseAuth,
  isFirebaseClientConfigured,
} from '@/src/lib/firebase/client';
import { ADMIN_ROUTES, DEFAULT_AFTER_LOGIN, safeAfterLoginRoute } from '@/src/lib/routes';

type FormState = {
  email: string;
  password: string;
};

type StatusState =
  | { state: 'idle' }
  | { state: 'submitting' }
  | { state: 'success' }
  | { state: 'error'; message: string };

async function postAdminSession(idToken: string) {
  const response = await fetch('/api/admin/session', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken }),
  });

  if (!response.ok) {
    let message = 'Anmeldung fehlgeschlagen.';
    try {
      const payload = (await response.json()) as { error?: string };
      switch (payload.error) {
        case 'missing_admin_role':
          message = 'Dein Konto besitzt keine Admin-Rolle.';
          break;
        case 'missing_id_token':
          message = 'Es fehlt ein gültiges ID-Token.';
          break;
        case 'invalid_payload':
          message = 'Die Anmeldeanfrage war ungültig.';
          break;
        default:
          message = 'Die Sitzung konnte nicht erstellt werden.';
          break;
      }
    } catch {
      message = 'Die Sitzung konnte nicht erstellt werden.';
    }

    throw new Error(message);
  }
}

export default function AdminLoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [form, setForm] = useState<FormState>({ email: '', password: '' });
  const [status, setStatus] = useState<StatusState>({ state: 'idle' });
  const [isPending, startTransition] = useTransition();

  const configured = isFirebaseClientConfigured();

  const nextParam = searchParams?.get('next') ?? undefined;
  const nextRoute = safeAfterLoginRoute(nextParam);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!configured) {
      setStatus({
        state: 'error',
        message: 'Firebase ist noch nicht konfiguriert. Bitte die Umgebungsvariablen prüfen.',
      });
      return;
    }

    setStatus({ state: 'submitting' });

    try {
      const auth = await getFirebaseAuth();
      const { user } = await signInWithEmailAndPassword(auth, form.email, form.password);
      const idToken = await user.getIdToken(true);

      await postAdminSession(idToken);
      await signOut(auth);

      setStatus({ state: 'success' });
      startTransition(() => {
        router.replace(
          nextRoute === DEFAULT_AFTER_LOGIN ? ADMIN_ROUTES.dashboard.href : nextRoute
        );
        router.refresh();
      });
    } catch (error) {
      console.error('[admin-login] failed', error);
      if (error instanceof FirebaseClientConfigError) {
        setStatus({
          state: 'error',
          message: 'Firebase-Konfiguration fehlt oder ist unvollständig.',
        });
        return;
      }

      const fallback =
        error instanceof Error ? error.message : 'E-Mail oder Passwort sind ungültig.';
      setStatus({ state: 'error', message: fallback });
    }
  }

  const disabled = status.state === 'submitting' || isPending;

  return (
    <form onSubmit={handleSubmit} className="space-y-6" noValidate>
      <div className="space-y-2">
        <label htmlFor="email" className="block text-sm font-medium text-slate-700">
          E-Mail-Adresse
        </label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          required
          value={form.email}
          onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
          className="w-full rounded-md border border-subtle bg-white px-4 py-2 text-base text-slate-900 shadow-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
      </div>
      <div className="space-y-2">
        <label htmlFor="password" className="block text-sm font-medium text-slate-700">
          Passwort
        </label>
        <input
          id="password"
          type="password"
          autoComplete="current-password"
          required
          value={form.password}
          onChange={(event) => setForm((prev) => ({ ...prev, password: event.target.value }))}
          className="w-full rounded-md border border-subtle bg-white px-4 py-2 text-base text-slate-900 shadow-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30"
        />
      </div>
      <p className="text-xs text-slate-500">
        Nur für Administrator:innen. Deine Anmeldung erzeugt ein sicheres Session-Cookie.
      </p>
      {status.state === 'error' ? (
        <div role="alert" className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {status.message}
        </div>
      ) : null}
      <button
        type="submit"
        disabled={disabled}
        className="w-full rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground shadow-md transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-not-allowed disabled:opacity-60"
      >
        {status.state === 'submitting' ? 'Anmeldung läuft …' : 'Anmelden'}
      </button>
    </form>
  );
}
