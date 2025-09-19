export type Role = 'admin' | 'owner' | 'operator';

export type DevUser = {
  uid: string;
  email: string;
  role: Role;
};
