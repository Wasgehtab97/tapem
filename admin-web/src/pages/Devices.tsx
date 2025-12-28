import { useParams } from 'react-router-dom';

export function Devices() {
  const { gymId } = useParams();
  return (
    <div className="page">
      <h1>Geräte {gymId ? `für ${gymId}` : ''}</h1>
      <p className="muted">Geräte-CRUD folgt nach Functions-Anbindung.</p>
    </div>
  );
}
