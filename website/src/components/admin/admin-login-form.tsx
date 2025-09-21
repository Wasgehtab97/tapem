'use client';

import React, { useMemo, useState } from 'react';
import { getFirebaseAuth, isFirebaseClientConfigured } from '@/src/lib/firebase/client';
import { signInWithEmailAndPassword } from 'firebase/auth';

function mapAuthError(error: unknown): string {
  if (error && typeof error === 'object' && 'code' in error && typeof (error as any).code === 'string') {
    const code = (error as any).code as string;
    switch (code) {
      case 'auth/invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'auth/user-not-found':
        return 'Kein Konto für diese E-Mail gefunden.';
      case 'auth/wrong-password':
      case 'auth/invalid-credential':
        return 'E-Mail oder Passwort ist falsch.';
      case 'auth/user-disabled':
        return 'Dieses Konto wurde deaktiviert.';
      default:
        break;
    }
  }

  if (error instanceof Error && error.message) {
    return error.message;
  }

  return 'Anmeldung fehlgeschlagen.';
}

export default function AdminLoginForm() {
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const clientOk = useMemo(() => isFirebaseClientConfigured(), []);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setErr(null);

    if (!clientOk) {
      setErr('Firebase ist noch nicht konfiguriert.');
      return;
    }

    setBusy(true);
    try {
      const auth = await getFirebaseAuth();
      const credential = await signInWithEmailAndPassword(auth, email.trim(), pw);
      const idToken = await credential.user.getIdToken(true);
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      });

      if (response.status === 204) {
        window.location.href = '/admin';
        return;
      }

      let message = 'Anmeldung fehlgeschlagen.';
      try {
        const data = await response.json();
        const rawError = typeof data?.error === 'string' ? data.error : null;
        if (rawError === 'not-admin') {
          message = 'Kein Admin-Zugriff für dieses Konto.';
        } else if (rawError === 'missing-idToken') {
          message = 'Anfrage unvollständig. Bitte erneut versuchen.';
        } else if (rawError) {
          message = rawError;
        }
      } catch {
        // Ignorieren – keine valide JSON-Antwort.
      }
      setErr(message);
    } catch (error) {
      setErr(mapAuthError(error));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="grid gap-4">
      {!clientOk && (
        <div className="rounded-md border border-red-400 bg-red-100/10 p-3 text-red-200">
          Firebase ist noch nicht konfiguriert. Bitte die Umgebungsvariablen prüfen.
        </div>
      )}

      <label className="grid gap-2">
        <span className="text-sm opacity-80">E-Mail-Adresse</span>
        <input
          type="email"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className="rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2"
        />
      </label>

      <label className="grid gap-2">
        <span className="text-sm opacity-80">Passwort</span>
        <input
          type="password"
          required
          value={pw}
          onChange={(event) => setPw(event.target.value)}
          className="rounded-md border border-neutral-700 bg-neutral-900 px-3 py-2"
        />
      </label>

      {err && <div className="text-sm text-red-300">{err}</div>}

      <button disabled={busy || !clientOk} className="rounded-md bg-blue-600 px-4 py-2 disabled:opacity-50">
        {busy ? 'Anmelden…' : 'Anmelden'}
      </button>
    </form>
  );
}
