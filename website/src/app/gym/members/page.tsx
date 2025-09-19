import { requireRole } from '@/src/lib/auth/server';
import { gymMembersMock } from '@/src/server/mocks/gym';

export default async function GymMembersPage() {
  await requireRole(['owner', 'operator', 'admin']);

  return (
    <section className="space-y-6">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-slate-900">Mitgliederverwaltung</h1>
        <p className="text-sm text-slate-600">
          Überblick über aktive Nutzerinnen und Nutzer. Filter und Sortierung folgen mit der
          Firestore-Anbindung.
        </p>
      </header>
      <div className="flex flex-wrap gap-2 text-xs font-medium">
        <button
          type="button"
          className="rounded border border-dashed border-slate-300 px-3 py-1 text-slate-500"
          disabled
        >
          Filter hinzufügen (bald)
        </button>
        <button
          type="button"
          className="rounded border border-dashed border-slate-300 px-3 py-1 text-slate-500"
          disabled
        >
          Sortierung speichern (bald)
        </button>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-card-muted">
            <tr>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Mitglied
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Mitgliedschaft
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Status
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Letzter Check-in
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Check-ins (Woche)
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200 bg-card">
            {gymMembersMock.map((member) => (
              <tr key={member.id} className="hover:bg-card-muted">
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">
                  <div className="font-medium text-slate-900">{member.name}</div>
                  <div className="text-xs text-slate-500">{member.email}</div>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">{member.membership}</td>
                <td className="whitespace-nowrap px-4 py-3 text-sm">
                  <span
                    className={
                      'inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ' +
                      (member.status === 'aktiv'
                        ? 'bg-emerald-50 text-emerald-700'
                        : 'bg-amber-50 text-amber-700')
                    }
                  >
                    {member.status === 'aktiv' ? 'Aktiv' : 'Pausiert'}
                  </span>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">{member.lastCheckIn}</td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">{member.weeklyCheckIns}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-slate-500">
        Die Tabelle basiert auf Mock-Daten aus <code>src/server/mocks/gym.ts</code>. Mit der Firebase
        Integration werden echte Filter, Pagination und Exportfunktionen ergänzt.
      </p>
    </section>
  );
}
