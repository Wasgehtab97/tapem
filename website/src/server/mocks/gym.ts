export type GymKpi = {
  label: string;
  value: string;
  change: string;
};

export type GymMember = {
  id: string;
  name: string;
  email: string;
  membership: 'Basis' | 'Premium' | 'Elite';
  status: 'aktiv' | 'pausiert';
  lastCheckIn: string;
  weeklyCheckIns: number;
};

export type GymChallenge = {
  id: string;
  title: string;
  description: string;
  progress: number;
  participants: number;
  endsOn: string;
};

export type GymLeaderboardEntry = {
  id: string;
  member: string;
  avatarInitials: string;
  points: number;
  rank: number;
  streak: number;
};

export const gymOverviewKpis: GymKpi[] = [
  { label: 'Studios im Verbund', value: '12', change: '+2 seit letztem Monat' },
  { label: 'Aktive Mitglieder', value: '1.842', change: '+4,3 % vs. letzte Woche' },
  { label: 'Check-ins heute', value: '326', change: 'Ø 311 Check-ins/Tag' },
  { label: 'Neue Leads', value: '48', change: '+12 gegenüber gestern' },
];

export const gymMembersMock: GymMember[] = [
  {
    id: 'm-1001',
    name: 'Lena Fischer',
    email: 'lena.fischer@example.com',
    membership: 'Premium',
    status: 'aktiv',
    lastCheckIn: '2024-04-17 07:42',
    weeklyCheckIns: 4,
  },
  {
    id: 'm-1002',
    name: 'Jamal Aydin',
    email: 'jamal.aydin@example.com',
    membership: 'Basis',
    status: 'aktiv',
    lastCheckIn: '2024-04-16 18:22',
    weeklyCheckIns: 3,
  },
  {
    id: 'm-1003',
    name: 'Carla Nguyen',
    email: 'carla.nguyen@example.com',
    membership: 'Elite',
    status: 'aktiv',
    lastCheckIn: '2024-04-17 09:05',
    weeklyCheckIns: 6,
  },
  {
    id: 'm-1004',
    name: 'Timur Gruber',
    email: 'timur.gruber@example.com',
    membership: 'Premium',
    status: 'pausiert',
    lastCheckIn: '2024-04-03 15:54',
    weeklyCheckIns: 0,
  },
  {
    id: 'm-1005',
    name: 'Sophia Brandt',
    email: 'sophia.brandt@example.com',
    membership: 'Basis',
    status: 'aktiv',
    lastCheckIn: '2024-04-17 06:58',
    weeklyCheckIns: 5,
  },
  {
    id: 'm-1006',
    name: 'Diego Romero',
    email: 'diego.romero@example.com',
    membership: 'Premium',
    status: 'aktiv',
    lastCheckIn: '2024-04-16 20:31',
    weeklyCheckIns: 2,
  },
  {
    id: 'm-1007',
    name: 'Eva Hartmann',
    email: 'eva.hartmann@example.com',
    membership: 'Elite',
    status: 'aktiv',
    lastCheckIn: '2024-04-17 11:10',
    weeklyCheckIns: 7,
  },
  {
    id: 'm-1008',
    name: 'Noah Seidel',
    email: 'noah.seidel@example.com',
    membership: 'Basis',
    status: 'pausiert',
    lastCheckIn: '2024-03-28 17:44',
    weeklyCheckIns: 0,
  },
  {
    id: 'm-1009',
    name: 'Fatima Özdemir',
    email: 'fatima.oezdemir@example.com',
    membership: 'Premium',
    status: 'aktiv',
    lastCheckIn: '2024-04-17 08:17',
    weeklyCheckIns: 3,
  },
  {
    id: 'm-1010',
    name: 'Paul König',
    email: 'paul.koenig@example.com',
    membership: 'Basis',
    status: 'aktiv',
    lastCheckIn: '2024-04-15 19:46',
    weeklyCheckIns: 1,
  },
  {
    id: 'm-1011',
    name: 'Zara Mertens',
    email: 'zara.mertens@example.com',
    membership: 'Elite',
    status: 'aktiv',
    lastCheckIn: '2024-04-17 10:02',
    weeklyCheckIns: 6,
  },
  {
    id: 'm-1012',
    name: 'Kai Lehmann',
    email: 'kai.lehmann@example.com',
    membership: 'Premium',
    status: 'aktiv',
    lastCheckIn: '2024-04-14 16:12',
    weeklyCheckIns: 2,
  },
];

export const gymChallengesMock: GymChallenge[] = [
  {
    id: 'c-2001',
    title: 'Spring into Action',
    description: 'Sammle 12 Check-ins im April und sichere dir ein exklusives Merch-Paket.',
    progress: 68,
    participants: 324,
    endsOn: '30.04.2024',
  },
  {
    id: 'c-2002',
    title: 'Strength Sprint',
    description: 'Absolviere 5 Kraft-Workouts pro Woche über vier Wochen.',
    progress: 52,
    participants: 189,
    endsOn: '12.05.2024',
  },
  {
    id: 'c-2003',
    title: 'Weekend Warrior',
    description: 'Trainiere an mindestens drei Wochenenden hintereinander.',
    progress: 44,
    participants: 248,
    endsOn: '26.05.2024',
  },
];

export const gymLeaderboardMock: GymLeaderboardEntry[] = [
  { id: 'l-3001', member: 'Carla Nguyen', avatarInitials: 'CN', points: 980, rank: 1, streak: 18 },
  { id: 'l-3002', member: 'Eva Hartmann', avatarInitials: 'EH', points: 940, rank: 2, streak: 22 },
  { id: 'l-3003', member: 'Jamal Aydin', avatarInitials: 'JA', points: 910, rank: 3, streak: 9 },
  { id: 'l-3004', member: 'Fatima Özdemir', avatarInitials: 'FÖ', points: 880, rank: 4, streak: 14 },
  { id: 'l-3005', member: 'Lena Fischer', avatarInitials: 'LF', points: 860, rank: 5, streak: 11 },
];
