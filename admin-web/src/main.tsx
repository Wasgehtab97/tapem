import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './pages/App';
import './styles/base.css';
import { ActiveGymProvider } from './hooks/useActiveGym';

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <BrowserRouter>
      <ActiveGymProvider>
        <App />
      </ActiveGymProvider>
    </BrowserRouter>
  </React.StrictMode>
);
