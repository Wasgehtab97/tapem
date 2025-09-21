'use client';
import React, { useState } from 'react';
import { getFirebaseAuth, isFirebaseClientConfigured } from '@/src/lib/firebase/client';
import { signInWithEmailAndPassword } from 'firebase/auth';

export default function AdminLoginForm() {
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const clientOk = isFirebaseClientConfigured();

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null); setBusy(true);
    try {
      if (!clientOk) throw new Error('client-not-configured');
      const auth = await getFirebaseAuth();
      const cred = await signInWithEmailAndPassword(auth, email.trim(), pw);
      const idToken = await cred.user.getIdToken(/* forceRefresh */ true);
      const resp = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      });
      if (!resp.ok) throw new Error('login-endpoint-failed');
      // Redirect to /admin
      window.location.href = '/admin';
    } catch (e: any) {
      setErr(e?.message ?? 'unknown-error');
    } finally { setBusy(false); }
  }

  return (
    <form onSubmit={onSubmit} className="grid gap-4">
      {!clientOk && (
        <div className="rounded-md bg-red-100/10 border border-red-400 p-3 text-red-200">
          Firebase ist noch nicht konfiguriert. Bitte die Umgebungsvariablen prüfen.
        </div>
      )}

      <label className="grid gap-2">
        <span className="text-sm opacity-80">E-Mail-Adresse</span>
        <input type="email" required value={email} onChange={e=>setEmail(e.target.value)} className="px-3 py-2 rounded-md bg-neutral-900 border border-neutral-700" />
      </label>

      <label className="grid gap-2">
        <span className="text-sm opacity-80">Passwort</span>
        <input type="password" required value={pw} onChange={e=>setPw(e.target.value)} className="px-3 py-2 rounded-md bg-neutral-900 border border-neutral-700" />
      </label>

      {err && <div className="text-sm text-red-300">{err}</div>}

      <button disabled={busy || !clientOk} className="rounded-md px-4 py-2 bg-blue-600 disabled:opacity-50">
        {busy ? 'Anmelden…' : 'Anmelden'}
      </button>
    </form>
  );
}
