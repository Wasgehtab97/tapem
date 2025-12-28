import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
export function Card({ title, children }) {
    return (_jsxs("div", { className: "card", children: [title && _jsx("h3", { style: { marginTop: 0 }, children: title }), children] }));
}
