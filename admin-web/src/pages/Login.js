import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useState } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebase';
import { useNavigate, useLocation } from 'react-router-dom';
export function Login() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();
    const location = useLocation();
    const from = location.state?.from?.pathname || '/';
    async function handleSubmit(e) {
        e.preventDefault();
        setError(null);
        setLoading(true);
        try {
            await signInWithEmailAndPassword(auth, email, password);
            navigate(from, { replace: true });
        }
        catch (err) {
            setError(err?.message || 'Login fehlgeschlagen');
        }
        finally {
            setLoading(false);
        }
    }
    return (_jsx("div", { className: "page login-page", children: _jsxs("div", { className: "card", children: [_jsx("h1", { children: "tapem Admin" }), _jsx("p", { className: "muted", children: "Bitte mit Admin-Account anmelden." }), _jsxs("form", { onSubmit: handleSubmit, className: "form", children: [_jsxs("label", { children: ["E-Mail", _jsx("input", { value: email, onChange: (e) => setEmail(e.target.value), type: "email", required: true })] }), _jsxs("label", { children: ["Passwort", _jsx("input", { value: password, onChange: (e) => setPassword(e.target.value), type: "password", required: true })] }), _jsx("button", { type: "submit", disabled: loading, children: loading ? 'Anmelden…' : 'Anmelden' }), error && _jsx("p", { className: "error", children: error })] })] }) }));
}
