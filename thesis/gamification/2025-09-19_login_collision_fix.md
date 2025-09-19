# Prompt
Behebe den Build-Fehler „two parallel pages that resolve to the same path“ in Wasgehtab97/tapem (Branch a_gpt5, Ordner website/) und konsolidiere die Login-Routen so, dass die Multi-Domain-Logik (marketing/portal/admin) intakt bleibt.

# Ziel
Eine einzige, host-aware `/login`-Route bereitstellen, die sowohl für `portal.*` als auch `admin.*` korrekte Texte, Weiterleitungen und Meta-Daten liefert, damit das Projekt vercel-prod-bereit ist.

# Kontext (Dateien/Hosts)
- `website/src/app/(portal)/login/page.tsx`: Seite liest jetzt den Host, leitet Admin-Sessions weiter und rendert je nach Domain entweder das Admin-Formular oder den Portal-Dev-Stub.
- `website/src/components/admin/admin-login-form.tsx`: weiterverwendet für Admin-Host.
- `website/src/app/(admin)/login/page.tsx`: entfernt, um die doppelte Routen-Definition zu beseitigen.
- Hosts: `portal.*` zeigt weiterhin den Dev-Login, `admin.*` nutzt das Firebase-basierte Admin-Login mit Session-Cookie-Setup.

# Ergebnis (Build-Output/Screenshots)
- `npm run build` → ❌ scheitert, weil `next` nach fehlgeschlagenem `npm install` (HTTP 403 auf `firebase`) nicht verfügbar ist.
- `npm install` → ❌ blockiert durch npm-Registry-403 (vermutlich Policy/Offline-Constraint), daher kein vollständiger lokaler Build möglich.

# Abweichungen/Nacharbeiten
- Sobald npm-Registry-Zugriff möglich ist, erneut `npm install` und anschließend `npm run build` bzw. `vercel --prod` ausführen.
- Nach erfolgreichem Build sollten die Logs im Repo oder Deployment-Tool hinterlegt werden.
