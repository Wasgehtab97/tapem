function setCurrentYear() {
  const yearEl = document.getElementById("year");
  if (!yearEl) return;
  yearEl.textContent = new Date().getFullYear().toString();
}

function normalizeFormData(form) {
  const data = new FormData(form);
  const payload = {};
  for (const [key, value] of data.entries()) {
    payload[key] = typeof value === "string" ? value.trim() : value;
  }
  return payload;
}

function setStartedAt(form) {
  const input = form.querySelector('input[name="startedAt"]');
  if (!input) return;
  input.value = Date.now().toString();
}

function getEndpoint(form) {
  const endpoint = form.dataset.endpoint || "";
  if (location.hostname === "localhost" || location.hostname === "127.0.0.1") {
    return "http://127.0.0.1:5001/tap-em/us-central1/submitMarketingLead";
  }
  return endpoint || "/api/lead";
}

async function handleContactFormSubmit(event) {
  event.preventDefault();

  const form = event.currentTarget;
  const statusEl = form.querySelector(".form-status");
  const submitButton = form.querySelector('button[type="submit"]');

  const payload = normalizeFormData(form);
  if (statusEl) statusEl.textContent = "";

  if (!payload.name || !payload.email || !payload.message) {
    if (statusEl) statusEl.textContent = "Bitte Name, E-Mail und Nachricht ausfüllen.";
    return;
  }

  const endpoint = getEndpoint(form);
  const startedAt = Number(payload.startedAt || 0);
  const now = Date.now();
  if (!startedAt || now - startedAt < 2000) {
    if (statusEl) statusEl.textContent = "Bitte kurz warten und dann erneut senden.";
    return;
  }

  const body = {
    name: payload.name,
    email: payload.email,
    studio: payload.studio || "",
    phone: payload.phone || "",
    message: payload.message,
    company: payload.company || "",
    startedAtMs: startedAt,
  };

  try {
    if (submitButton) submitButton.disabled = true;
    if (statusEl) statusEl.textContent = "Sende…";

    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    const responseJson = await res.json().catch(() => null);
    if (!res.ok) {
      const message = responseJson?.error || "Senden fehlgeschlagen. Bitte per E-Mail kontaktieren.";
      if (statusEl) statusEl.textContent = message;
      return;
    }

    form.reset();
    setStartedAt(form);
    if (statusEl) statusEl.textContent = "Danke! Wir melden uns kurzfristig.";
  } catch {
    if (statusEl) statusEl.textContent = "Senden fehlgeschlagen. Bitte per E-Mail kontaktieren.";
  } finally {
    if (submitButton) submitButton.disabled = false;
  }
}

function wireContactForms() {
  document.querySelectorAll("form.contact-form").forEach((form) => {
    setStartedAt(form);
    form.addEventListener("submit", handleContactFormSubmit);
  });
}

setCurrentYear();
wireContactForms();

