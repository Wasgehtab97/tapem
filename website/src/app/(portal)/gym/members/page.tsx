import { requireRole } from '@/lib/auth/server';
import { gymMembersMock } from '@/server/mocks/gym';

export default async function GymMembersPage() {
  await requireRole(['owner', 'operator', 'admin']);

  return (
    <section className="space-y-6">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-page">Mitgliederverwaltung</h1>
        <p className="text-sm text-muted">
          Überblick über aktive Nutzerinnen und Nutzer. Filter und Sortierung folgen mit der
          Firestore-Anbindung.
        </p>
      </header>
      <div className="flex flex-wrap gap-2 text-xs font-medium">
        <button
          type="button"
          className="rounded border border-dashed border-subtle px-3 py-1 text-muted"
          disabled
        >
          Filter hinzufügen (bald)
        </button>
        <button
          type="button"
          className="rounded border border-dashed border-subtle px-3 py-1 text-muted"
          disabled
        >
          Sortierung speichern (bald)
        </button>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-[color:var(--page-border)]">
          <thead className="bg-card-muted">
            <tr>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Mitglied
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Mitgliedschaft
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Status
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Letzter Check-in
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Check-ins (Woche)
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[color:var(--page-border)] bg-card">
            {gymMembersMock.map((member) => (
              <tr key={member.id} className="hover:bg-card-muted">
                <td className="whitespace-nowrap px-4 py-3 text-sm text-page">
                  <div className="font-medium text-page">{member.name}</div>
                  <div className="text-xs text-muted">{member.email}</div>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-page">{member.membership}</td>
                <td className="whitespace-nowrap px-4 py-3 text-sm">
                  <span
                    className={
                      'inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ' +
                      (member.status === 'aktiv'
                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-200'
                        : 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-200')
                    }
                  >
                    {member.status === 'aktiv' ? 'Aktiv' : 'Pausiert'}
                  </span>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-page">{member.lastCheckIn}</td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-page">{member.weeklyCheckIns}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-muted">
        Die Tabelle basiert auf Mock-Daten aus <code>src/server/mocks/gym.ts</code>. Mit der Firebase
        Integration werden echte Filter, Pagination und Exportfunktionen ergänzt.
      </p>
    </section>
  );
}
