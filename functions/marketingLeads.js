const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

function setCors(req, res) {
  const origin = req.headers.origin;
  const allowList = new Set([
    "https://tapem.app",
    "https://www.tapem.app",
    "http://localhost:4173",
    "http://127.0.0.1:4173",
  ]);

  if (origin && allowList.has(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Vary", "Origin");
  } else {
    res.set("Access-Control-Allow-Origin", "*");
  }

  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Max-Age", "86400");
}

function getClientId(req) {
  const forwarded = (req.headers["x-forwarded-for"] || "").toString();
  const ip = forwarded.split(",")[0].trim() || (req.ip || "").toString();
  const ua = (req.headers["user-agent"] || "").toString();
  const raw = `${ip}|${ua}`;
  return crypto.createHash("sha256").update(raw).digest("hex");
}

function isValidEmail(email) {
  if (!email) return false;
  const value = email.trim();
  if (value.length > 254) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function cleanString(value, maxLen) {
  if (typeof value !== "string") return "";
  const cleaned = value.trim();
  if (cleaned.length > maxLen) return cleaned.slice(0, maxLen);
  return cleaned;
}

exports.submitMarketingLead = functions.https.onRequest(async (req, res) => {
  setCors(req, res);

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const body = req.body || {};
  const name = cleanString(body.name, 120);
  const email = cleanString(body.email, 254);
  const studio = cleanString(body.studio, 160);
  const phone = cleanString(body.phone, 40);
  const message = cleanString(body.message, 2000);
  const company = cleanString(body.company, 80);
  const startedAtMs = Number(body.startedAtMs || 0);
  const nowMs = Date.now();

  if (company) {
    res.status(200).json({ ok: true });
    return;
  }

  if (!name || !email || !message) {
    res.status(400).json({ error: "Bitte Name, E-Mail und Nachricht angeben." });
    return;
  }

  if (!isValidEmail(email)) {
    res.status(400).json({ error: "Bitte eine gültige E-Mail-Adresse angeben." });
    return;
  }

  if (!startedAtMs || nowMs - startedAtMs < 2000) {
    res.status(400).json({ error: "Bitte kurz warten und dann erneut senden." });
    return;
  }

  const db = admin.firestore();
  const clientId = getClientId(req);
  const rateRef = db.collection("marketingRateLimits").doc(clientId);
  const leadRef = db.collection("marketingLeads").doc();

  try {
    await db.runTransaction(async (tx) => {
      const rateSnap = await tx.get(rateRef);
      const lastAtMs = rateSnap.exists ? Number(rateSnap.data().lastAtMs || 0) : 0;

      if (lastAtMs && nowMs - lastAtMs < 60_000) {
        throw Object.assign(new Error("rate_limited"), { code: "rate_limited" });
      }

      tx.set(rateRef, { lastAtMs: nowMs }, { merge: true });
      tx.set(leadRef, {
        name,
        email,
        studio,
        phone,
        message,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        clientId,
        source: "marketing-website",
      });
    });

    res.status(200).json({ ok: true });
  } catch (err) {
    if (err && err.code === "rate_limited") {
      res.status(429).json({ error: "Bitte warte kurz und versuche es erneut." });
      return;
    }
    console.error("submitMarketingLead error", err);
    res.status(500).json({ error: "Serverfehler. Bitte per E-Mail kontaktieren." });
  }
});

