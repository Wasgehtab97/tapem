import { Navigate, Route, Routes } from 'react-router-dom';
import { AuthGate } from '../components/AuthGate';
import { Dashboard } from './Dashboard';
import { Login } from './Login';
import { GymDetail } from './GymDetail';
import { Users } from './Users';
import { Devices } from './Devices';
import { Shell } from '../components/Shell';
import { useActiveGym } from '../hooks/useActiveGym';

function RequireGym({ children }: { children: JSX.Element }) {
  const { activeGym } = useActiveGym();
  if (!activeGym?.id) {
    return <Navigate to="/" replace />;
  }
  return children;
}

function GymRedirect() {
  const { activeGym } = useActiveGym();
  if (!activeGym?.id) {
    return <Navigate to="/" replace />;
  }
  return <Navigate to={`/gyms/${activeGym.id}`} replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/*"
        element={
          <AuthGate>
            <Shell>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/gyms" element={<GymRedirect />} />
                <Route
                  path="/gyms/:gymId"
                  element={
                    <RequireGym>
                      <GymDetail />
                    </RequireGym>
                  }
                />
                <Route
                  path="/users"
                  element={
                    <RequireGym>
                      <Users />
                    </RequireGym>
                  }
                />
                <Route
                  path="/gyms/:gymId/devices"
                  element={
                    <RequireGym>
                      <Devices />
                    </RequireGym>
                  }
                />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Shell>
          </AuthGate>
        }
      />
    </Routes>
  );
}
