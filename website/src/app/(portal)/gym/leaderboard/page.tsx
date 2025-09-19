import { requireRole } from '@/src/lib/auth/server';
import { gymLeaderboardMock } from '@/src/server/mocks/gym';

export default async function GymLeaderboardPage() {
  await requireRole(['owner', 'operator', 'admin']);

  return (
    <section className="space-y-6">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-slate-900">Leaderboard</h1>
        <p className="text-sm text-slate-600">
          Motiviert Mitglieder durch transparente Gamification. Die Tabelle wird zukünftig mit
          Firestore-Scores gespeist.
        </p>
      </header>
      <div className="overflow-x-auto rounded-lg border border-subtle bg-card shadow-sm">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-card-muted">
            <tr>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Rang
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Mitglied
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Punkte
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Aktuelle Streak
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {gymLeaderboardMock.map((entry) => (
              <tr key={entry.id} className="hover:bg-card-muted">
                <td className="whitespace-nowrap px-4 py-3 text-sm font-semibold text-slate-700">
                  #{entry.rank}
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">
                  <div className="flex items-center gap-3">
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-900 text-xs font-semibold text-white">
                      {entry.avatarInitials}
                    </span>
                    <span className="font-medium text-slate-900">{entry.member}</span>
                  </div>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm font-semibold text-slate-900">
                  {entry.points} XP
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">{entry.streak} Tage</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-slate-500">
        Ranking basiert auf Mock-Werten. Für das finale Produkt werden Echtzeit-Punkte und Badges
        aus dem Analytics-Backend übernommen.
      </p>
    </section>
  );
}
