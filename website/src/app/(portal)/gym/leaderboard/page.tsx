import { requireRole } from '@/lib/auth/server';
import { gymLeaderboardMock } from '@/server/mocks/gym';

export default async function GymLeaderboardPage() {
  await requireRole(['owner', 'operator', 'admin']);

  return (
    <section className="space-y-6">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-page">Leaderboard</h1>
        <p className="text-sm text-muted">
          Motiviert Mitglieder durch transparente Gamification. Die Tabelle wird zukünftig mit
          Firestore-Scores gespeist.
        </p>
      </header>
      <div className="overflow-x-auto rounded-lg border border-subtle bg-card shadow-sm">
        <table className="min-w-full divide-y divide-[color:var(--page-border)]">
          <thead className="bg-card-muted">
            <tr>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Rang
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Mitglied
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Punkte
              </th>
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Aktuelle Streak
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[color:var(--page-border)]">
            {gymLeaderboardMock.map((entry) => (
              <tr key={entry.id} className="hover:bg-card-muted">
                <td className="whitespace-nowrap px-4 py-3 text-sm font-semibold text-page">
                  #{entry.rank}
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-page">
                  <div className="flex items-center gap-3">
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-xs font-semibold text-primary-foreground">
                      {entry.avatarInitials}
                    </span>
                    <span className="font-medium text-page">{entry.member}</span>
                  </div>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm font-semibold text-page">
                  {entry.points} XP
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">{entry.streak} Tage</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-muted">
        Ranking basiert auf Mock-Werten. Für das finale Produkt werden Echtzeit-Punkte und Badges
        aus dem Analytics-Backend übernommen.
      </p>
    </section>
  );
}
