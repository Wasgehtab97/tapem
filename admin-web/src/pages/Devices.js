import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import { useParams } from 'react-router-dom';
export function Devices() {
    const { gymId } = useParams();
    return (_jsxs("div", { className: "page", children: [_jsxs("h1", { children: ["Ger\u00E4te ", gymId ? `für ${gymId}` : ''] }), _jsx("p", { className: "muted", children: "Ger\u00E4te-CRUD folgt nach Functions-Anbindung." })] }));
}
