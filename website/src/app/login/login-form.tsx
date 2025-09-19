'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import type { Route } from 'next';
import { useState } from 'react';

// Whitelist der erlaubten Zielrouten nach Login (bei Bedarf erweitern)
const ALLOWED_AFTER_LOGIN = [
  '/gym',
  '/gym/members',
  '/gym/challenges',
  '/gym/leaderboard',
  '/admin',
] as const;

type AllowedRoute = (typeof ALLOWED_AFTER_LOGIN)[number];
const DEFAULT_AFTER_LOGIN: AllowedRoute = '/gym';

function isAllowedRoute(v: string | null): v is AllowedRoute {
  return !!v && (ALLOWED_AFTER_LOGIN as readonly string[]).includes(v);
}

export default function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(formData: FormData) {
    setError(null);
    setSubmitting(true);

    try {
      const email = (formData.get('email') as string | null) ?? '';
      const role = (formData.get('role') as string | null) ?? 'owner';

      // Dev-Login-API (setzt Cookies). In Production sollte diese Route 403 liefern.
      const res = await fetch('/api/dev/login', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email, role }),
      });

      if (!res.ok) {
        throw new Error(`Login fehlgeschlagen (${res.status})`);
      }

      // Zielroute bestimmen (nur Whitelist zulassen)
      const nextParam = searchParams.get('next');
      const target: Route = (isAllowedRoute(nextParam) ? nextParam : DEFAULT_AFTER_LOGIN) as Route;

      router.push(target);
      router.refresh();
    } catch (e: any) {
      setError(e?.message ?? 'Unbekannter Fehler beim Login.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form action={onSubmit} className="max-w-md space-y-4">
      <div className="rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
        <strong>Dev-Login (Stub):</strong> Nur für Preview/Entwicklung. In Production deaktiviert.
      </div>

      <div className="space-y-1">
        <label htmlFor="email" className="block text-sm font-medium text-slate-700">
          E-Mail (optional)
        </label>
        <input
          id="email"
          name="email"
          type="email"
          placeholder="you@example.com"
          className="w-full rounded border border-slate-300 px-3 py-2 text-sm outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900"
        />
      </div>

      <div className="space-y-1">
        <label htmlFor="role" className="block text-sm font-medium text-slate-700">
          Rolle
        </label>
        <select
          id="role"
          name="role"
          defaultValue="owner"
          className="w-full rounded border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900"
        >
          <option value="owner">owner</option>
          <option value="operator">operator</option>
          <option value="admin">admin</option>
        </select>
      </div>

      {error ? <p className="text-sm text-red-600">{error}</p> : null}

      <button
        type="submit"
        disabled={submitting}
        className="inline-flex items-center justify-center rounded bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-800 disabled:opacity-50"
      >
        {submitting ? 'Anmelden…' : 'Anmelden'}
      </button>
    </form>
  );
}
