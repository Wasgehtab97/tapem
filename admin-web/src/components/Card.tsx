import { ReactNode } from 'react';

interface Props {
  title?: string;
  children: ReactNode;
}

export function Card({ title, children }: Props) {
  return (
    <div className="card">
      {title && <h3 style={{ marginTop: 0 }}>{title}</h3>}
      {children}
    </div>
  );
}
