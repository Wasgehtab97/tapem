export type Role = 'admin' | 'owner' | 'operator';

export type DevUser = {
  uid: string;
  email: string;
  role: Role;
};

export type AuthenticatedUserSource = 'dev-stub' | 'firebase-session';

export type AuthenticatedUser = {
  uid: string;
  email: string;
  role: Role;
  displayName?: string | null;
  source: AuthenticatedUserSource;
  claims?: Record<string, unknown>;
  roleSource?: 'claim' | 'profile';
};
