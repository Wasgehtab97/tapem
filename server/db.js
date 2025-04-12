require('dotenv').config(); // Umgebungsvariablen laden

const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 200, // maximal 200 Verbindungen
  idleTimeoutMillis: 30000, // Verbindungen, die 30 Sekunden inaktiv sind, werden geschlossen
  ssl: { rejectUnauthorized: false } // Aktiviert SSL und akzeptiert alle Zertifikate (geeignet für Render)
});

module.exports = pool;
