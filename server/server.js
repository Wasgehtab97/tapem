// Laden der Umgebungsvariablen aus der .env-Datei
require('dotenv').config();

const express = require('express');
const path = require('path');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto'); // Für die Schlüsselgenerierung
const pool = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
// Falls ein Web-Build existiert, können folgende Zeilen aktiviert werden:
// app.use(express.static(path.join(__dirname, '../frontend/build')));
// app.get('*', (req, res) => {
//   res.sendFile(path.join(__dirname, '../frontend/build', 'index.html'));
// });

/**
 * Konvertiert ein Datum in die deutsche Zeitzone ("Europe/Berlin")
 * und gibt das Datum im Format "YYYY-MM-DD" zurück.
 */
function getLocalDateString(date = new Date()) {
  const germanDate = new Date(
    date.toLocaleString("en-US", { timeZone: "Europe/Berlin" })
  );
  const year = germanDate.getFullYear();
  const month = (germanDate.getMonth() + 1).toString().padStart(2, '0');
  const day = germanDate.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Middleware, die überprüft, ob der Benutzer ein Admin ist.
 */
function adminOnly(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Kein Token gefunden.' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Nicht autorisiert.' });
    }
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Ungültiger Token.' });
  }
}

/**
 * Middleware zur Token-Überprüfung (für Endpunkte, die keine Admin-Rechte benötigen)
 */
function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'Kein Token gefunden.' });
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Ungültiger Token.' });
  }
}

// ----------------------
// Benutzer-Endpunkte
// ----------------------

app.get('/api/user/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      'SELECT id, name, exp_progress, division_index, current_streak, role, coach_id FROM users WHERE id = $1',
      [id]
    );
    if (!result.rows.length)
      return res.status(404).json({ error: 'Benutzer nicht gefunden' });
    res.json({ data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Abrufen der User-Daten:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der User-Daten' });
  }
});

app.get('/api/streak/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const result = await pool.query(
      'SELECT current_streak FROM users WHERE id = $1',
      [userId]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Benutzer nicht gefunden.' });
    }
    res.json({ data: { current_streak: result.rows[0].current_streak } });
  } catch (error) {
    console.error('Fehler beim Abrufen der Streak:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Streak' });
  }
});

app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, exp_progress, division_index, current_streak FROM users ORDER BY name'
    );
    res.json({ message: 'Alle Nutzer erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen aller Nutzer:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen aller Nutzer' });
  }
});

app.post('/api/register', async (req, res) => {
  const { name, email, password, membershipNumber } = req.body;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email))
    return res.status(400).json({ error: 'Ungültige E-Mail-Adresse.' });
  try {
    const existingByMembership = await pool.query(
      'SELECT * FROM users WHERE membership_number = $1',
      [membershipNumber]
    );
    if (existingByMembership.rows.length)
      return res.status(400).json({ error: 'Diese Mitgliedsnummer ist bereits vergeben.' });
    const existingByName = await pool.query('SELECT * FROM users WHERE name = $1', [name]);
    if (existingByName.rows.length)
      return res.status(400).json({ error: 'Dieser Name ist bereits vergeben.' });
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const newUserResult = await pool.query(
      'INSERT INTO users (name, email, password, membership_number, exp_progress, division_index, current_streak) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [name, email, hashedPassword, membershipNumber, 0, 0, 0]
    );
    const user = newUserResult.rows[0];
    const token = jwt.sign(
      { userId: user.id, role: user.role, userExp: user.exp_progress },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );
    res.json({ message: 'Benutzer erfolgreich registriert', token, refreshToken });
  } catch (error) {
    console.error('Registrierungsfehler:', error.message);
    res.status(500).json({ error: 'Serverfehler bei der Registrierung' });
  }
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (!userResult.rows.length)
      return res.status(401).json({ error: 'Ungültige Anmeldedaten' });
    const user = userResult.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword)
      return res.status(401).json({ error: 'Ungültige Anmeldedaten' });
    const token = jwt.sign(
      { userId: user.id, role: user.role, userExp: user.exp_progress },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      message: 'Login erfolgreich',
      token,
      refreshToken,
      userId: user.id,
      username: user.name,
      role: user.role,
      exp_progress: user.exp_progress,
      division_index: user.division_index,
      current_streak: user.current_streak,
    });
  } catch (error) {
    console.error('Login-Fehler:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Login' });
  }
});

// Neuer Endpoint: Token Refresh
app.post('/api/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ error: 'Kein Refresh Token übermittelt.' });
  try {
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const newToken = jwt.sign(
      { userId: decoded.userId },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    res.json({ token: newToken });
  } catch (error) {
    console.error('Refresh-Fehler:', error.message);
    res.status(401).json({ error: 'Ungültiger Refresh Token.' });
  }
});

// ----------------------
// Geräte & Trainingsdaten
// ----------------------

app.post('/api/devices', adminOnly, async (req, res) => {
  const { name, exercise_mode } = req.body;
  if (!name)
    return res.status(400).json({ error: 'Name ist erforderlich.' });
  try {
    const secretCode = crypto.randomBytes(8).toString('hex');
    const result = await pool.query(
      'INSERT INTO devices (name, exercise_mode, secret_code) VALUES ($1, $2, $3) RETURNING *',
      [name, exercise_mode, secretCode]
    );
    res.json({ message: 'Gerät erfolgreich erstellt', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Erstellen des Geräts:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Erstellen des Geräts' });
  }
});

app.get('/api/device_by_secret', async (req, res) => {
  const { device_id, secret_code } = req.query;
  if (!device_id || !secret_code) {
    return res.status(400).json({ error: 'device_id und secret_code sind erforderlich.' });
  }
  try {
    const result = await pool.query(
      'SELECT * FROM devices WHERE id = $1 AND secret_code = $2',
      [device_id, secret_code]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Gerät nicht gefunden oder secret_code stimmt nicht überein.' });
    }
    res.json({ message: 'Gerät erfolgreich abgerufen', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Abrufen des Geräts mit secret_code:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen des Geräts' });
  }
});

app.post('/api/training', async (req, res) => {
  const { userId, deviceId, trainingDate, data } = req.body;
  if (!userId || !deviceId || !trainingDate || !data || !Array.isArray(data) || data.length === 0) {
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  }
  
  try {
    const checkResult = await pool.query(
      'SELECT COUNT(*) FROM training_history WHERE user_id = $1 AND training_date = $2',
      [userId, trainingDate]
    );
    const alreadyTrained = parseInt(checkResult.rows[0].count) > 0;
    
    const insertedRows = [];
    for (let i = 0; i < data.length; i++) {
      const set = data[i];
      const setNumber = set.setNumber || i + 1;
      if (set.reps === undefined || set.weight === undefined || set.reps === "" || set.weight === "") {
        return res.status(400).json({ error: 'Alle Sätze müssen vollständig ausgefüllt sein.' });
      }
      const result = await pool.query(
        'INSERT INTO training_history (user_id, device_id, training_date, exercise, sets, reps, weight) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
        [
          userId,
          deviceId,
          trainingDate,
          set.exercise,
          setNumber,
          parseInt(set.reps),
          parseFloat(set.weight)
        ]
      );
      insertedRows.push(result.rows[0]);
    }
    
    if (!alreadyTrained) {
      const userResult = await pool.query(
        'SELECT exp_progress, division_index, current_streak FROM users WHERE id = $1',
        [userId]
      );
      let { exp_progress, division_index, current_streak } = userResult.rows[0];
      const newExp = exp_progress + 25;
      const divisionsGained = Math.floor(newExp / 1000);
      const remainingExp = newExp % 1000;
      
      const lastTrainingResult = await pool.query(
        'SELECT MAX(training_date) AS last_date FROM training_history WHERE user_id = $1 AND training_date < $2',
        [userId, trainingDate]
      );
      
      let newStreak;
      if (!lastTrainingResult.rows[0].last_date) {
        newStreak = 1;
      } else {
        const lastDate = new Date(lastTrainingResult.rows[0].last_date);
        const currentDate = new Date(trainingDate);
        const diffDays = Math.floor((currentDate - lastDate) / (1000 * 60 * 60 * 24));
        newStreak = (diffDays >= 4) ? 1 : current_streak + 1;
      }
      
      await pool.query(
        'UPDATE users SET division_index = division_index + $1, exp_progress = $2, current_streak = $3 WHERE id = $4',
        [divisionsGained, remainingExp, newStreak, userId]
      );
    }
    
    res.json({ message: 'Trainingseinheit erfolgreich gespeichert', data: insertedRows });
  } catch (error) {
    console.error('Fehler beim Speichern der Trainingsdaten:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Speichern der Trainingsdaten' });
  }
});

app.get('/api/device/:id', async (req, res) => {
  const { id: deviceId } = req.params;
  if (!deviceId || isNaN(deviceId))
    return res.status(400).json({ error: 'Ungültige Geräte-ID' });
  try {
    const result = await pool.query(
      'SELECT * FROM training_history WHERE device_id = $1',
      [deviceId]
    );
    if (!result.rows.length)
      return res.status(404).json({ error: `Keine Trainingshistorie für Gerät ${deviceId} gefunden` });
    res.json({ message: `Trainingshistorie für Gerät ${deviceId}`, data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Trainingshistorie:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Trainingshistorie' });
  }
});

app.get('/api/history/:userId', async (req, res) => {
  const { userId } = req.params;
  if (!userId)
    return res.status(400).json({ error: 'Ungültige Nutzer-ID' });
  let query = 'SELECT * FROM training_history WHERE user_id = $1';
  const values = [userId];

  if (req.query.exercise) {
    query += ' AND exercise = $' + (values.length + 1);
    values.push(req.query.exercise);
  }
  if (req.query.deviceId) {
    query += ' AND device_id = $' + (values.length + 1);
    values.push(req.query.deviceId);
  }
  query += ' ORDER BY training_date DESC';
  try {
    const result = await pool.query(query, values);
    if (!result.rows.length)
      return res.status(404).json({ error: 'Keine Trainingshistorie gefunden' });
    res.json({ message: 'Trainingshistorie erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Trainingshistorie:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Trainingshistorie' });
  }
});

app.get('/api/devices', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM devices ORDER BY id');
    res.json({ message: 'Geräte erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Geräte:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Geräte' });
  }
});

app.put('/api/devices/:id', adminOnly, async (req, res) => {
  const { id } = req.params;
  const { name, exercise_mode, secret_code } = req.body;
  if (!id || !name)
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  try {
    const result = await pool.query(
      'UPDATE devices SET name = $1, exercise_mode = COALESCE($2, exercise_mode), secret_code = COALESCE($3, secret_code) WHERE id = $4 RETURNING *',
      [name, exercise_mode, secret_code, id]
    );
    if (!result.rows.length)
      return res.status(404).json({ error: 'Gerät nicht gefunden.' });
    res.json({ message: 'Gerät erfolgreich aktualisiert', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Aktualisieren des Geräts:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Aktualisieren des Geräts' });
  }
});

// ----------------------
// Affiliate-Endpunkte
// ----------------------

app.get('/api/affiliate_offers', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const result = await pool.query(
      `SELECT * FROM affiliate_offers 
       WHERE (start_date IS NULL OR start_date <= $1)
         AND (end_date IS NULL OR end_date >= $1)
       ORDER BY id`,
      [today]
    );
    res.json({ message: 'Affiliate-Angebote erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Affiliate-Angebote:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Affiliate-Angebote' });
  }
});

app.post('/api/affiliate_click', async (req, res) => {
  const { offer_id, user_id } = req.body;
  if (!offer_id)
    return res.status(400).json({ error: 'Offer ID ist erforderlich.' });
  try {
    const result = await pool.query(
      'INSERT INTO affiliate_clicks (offer_id, user_id) VALUES ($1, $2) RETURNING *',
      [offer_id, user_id]
    );
    res.json({ message: 'Klick erfolgreich erfasst', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Erfassen des Klicks:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Erfassen des Klicks' });
  }
});

app.post('/api/affiliate_conversion', async (req, res) => {
  const { offer_id, user_id, conversion_value } = req.body;
  if (!offer_id || !conversion_value)
    return res.status(400).json({ error: 'Offer ID und Conversion Value sind erforderlich.' });
  try {
    const result = await pool.query(
      'UPDATE affiliate_clicks SET conversion_value = $1, converted_at = NOW() WHERE offer_id = $2 AND user_id = $3 RETURNING *',
      [conversion_value, offer_id, user_id]
    );
    res.json({ message: 'Conversion erfolgreich erfasst', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Erfassen der Conversion:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Erfassen der Conversion' });
  }
});

// ----------------------
// Reporting & Feedback
// ----------------------

app.get('/api/reporting/usage', async (req, res) => {
  const { startDate, endDate, deviceId } = req.query;
  let values = [], paramIndex = 1;
  let subQuery = `SELECT device_id, user_id, training_date FROM training_history`;
  let subConditions = [];
  if (startDate && endDate) {
    subConditions.push(`training_date BETWEEN $${paramIndex} AND $${paramIndex + 1}`);
    values.push(startDate, endDate);
    paramIndex += 2;
  }
  if (subConditions.length)
    subQuery += " WHERE " + subConditions.join(" AND ");
  subQuery += " GROUP BY device_id, user_id, training_date";
  let mainQuery = `SELECT s.device_id, COUNT(*) AS session_count FROM (${subQuery}) s`;
  let mainConditions = [];
  if (deviceId) {
    mainConditions.push(`s.device_id = $${paramIndex}`);
    values.push(deviceId);
    paramIndex++;
  }
  if (mainConditions.length)
    mainQuery += " WHERE " + mainConditions.join(" AND ");
  mainQuery += " GROUP BY s.device_id";
  try {
    const result = await pool.query(mainQuery, values);
    res.json({ message: 'Nutzungshäufigkeit erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Nutzungshäufigkeit:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Nutzungshäufigkeit' });
  }
});

app.post('/api/feedback', async (req, res) => {
  const { userId, deviceId, feedback_text } = req.body;
  if (!userId || !deviceId || !feedback_text)
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  try {
    const result = await pool.query(
      'INSERT INTO feedback (user_id, device_id, feedback_text, created_at, status) VALUES ($1, $2, $3, NOW(), $4) RETURNING *',
      [userId, deviceId, feedback_text, 'neu']
    );
    res.json({ message: 'Feedback erfolgreich gesendet', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Absenden des Feedbacks:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Absenden des Feedbacks' });
  }
});

app.get('/api/feedback', async (req, res) => {
  const { deviceId, status } = req.query;
  let query = 'SELECT * FROM feedback', values = [], conditions = [];
  if (deviceId) {
    conditions.push(`device_id = $${values.length + 1}`);
    values.push(deviceId);
  }
  if (status) {
    conditions.push(`status = $${values.length + 1}`);
    values.push(status);
  }
  if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
  try {
    const result = await pool.query(query, values);
    res.json({ message: 'Feedback erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen des Feedbacks:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen des Feedbacks' });
  }
});

app.put('/api/feedback/:id', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  if (!status)
    return res.status(400).json({ error: 'Status ist erforderlich.' });
  try {
    const result = await pool.query(
      'UPDATE feedback SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );
    if (!result.rows.length)
      return res.status(404).json({ error: 'Feedback nicht gefunden.' });
    res.json({ message: 'Feedback erfolgreich aktualisiert', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Aktualisieren des Feedback-Status:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Aktualisieren des Feedback-Status' });
  }
});

// ----------------------
// Trainingspläne
// ----------------------

app.post('/api/training-plans', async (req, res) => {
  const { userId, name } = req.body;
  if (!userId || !name)
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  try {
    const result = await pool.query(
      'INSERT INTO training_plans (userId, name, created_at, status) VALUES ($1, $2, NOW(), $3) RETURNING *',
      [userId, name, 'inaktiv']
    );
    res.json({ message: 'Trainingsplan erfolgreich erstellt', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Erstellen des Trainingsplans:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Erstellen des Trainingsplans' });
  }
});

app.get('/api/training-plans/:userId', async (req, res) => {
  const { userId } = req.params;
  if (!userId)
    return res.status(400).json({ error: 'Ungültige Nutzer-ID' });
  try {
    const result = await pool.query(
      `SELECT tp.*, 
         COALESCE(json_agg(
           json_build_object(
             'device_id', tpe.device_id,
             'exercise_order', tpe.exercise_order,
             'device_name', d.name
           )
         ) FILTER (WHERE tpe.id IS NOT NULL), '[]') AS exercises
       FROM training_plans tp
       LEFT JOIN training_plan_exercises tpe ON tp.id = tpe.plan_id
       LEFT JOIN devices d ON tpe.device_id = d.id
       WHERE tp.userId = $1
       GROUP BY tp.id
       ORDER BY tp.created_at DESC`,
      [userId]
    );
    res.json({ message: 'Trainingspläne erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Trainingspläne:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Trainingspläne' });
  }
});

app.put('/api/training-plans/:planId', async (req, res) => {
  const { planId } = req.params;
  const { exercises } = req.body;
  if (!planId || !exercises || !Array.isArray(exercises))
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  try {
    await pool.query('DELETE FROM training_plan_exercises WHERE plan_id = $1', [planId]);
    for (const ex of exercises) {
      const { device_id, exercise_order } = ex;
      await pool.query(
        'INSERT INTO training_plan_exercises (plan_id, device_id, exercise_order) VALUES ($1, $2, $3)',
        [planId, device_id, exercise_order]
      );
    }
    const result = await pool.query(
      `SELECT tp.*, 
         COALESCE(json_agg(
           json_build_object(
             'device_id', tpe.device_id,
             'exercise_order', tpe.exercise_order,
             'device_name', d.name
           )
         ) FILTER (WHERE tpe.id IS NOT NULL), '[]') AS exercises
       FROM training_plans tp
       LEFT JOIN training_plan_exercises tpe ON tp.id = tpe.plan_id
       LEFT JOIN devices d ON tpe.device_id = d.id
       WHERE tp.id = $1
       GROUP BY tp.id`,
      [planId]
    );
    res.json({ message: 'Trainingsplan erfolgreich aktualisiert', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Aktualisieren des Trainingsplans:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Aktualisieren des Trainingsplans' });
  }
});

app.delete('/api/training-plans/:planId', async (req, res) => {
  const { planId } = req.params;
  if (!planId)
    return res.status(400).json({ error: 'Ungültige Plan-ID' });
  try {
    await pool.query('DELETE FROM training_plan_exercises WHERE plan_id = $1', [planId]);
    await pool.query('DELETE FROM training_plans WHERE id = $1', [planId]);
    res.json({ message: 'Trainingsplan erfolgreich gelöscht' });
  } catch (error) {
    console.error('Fehler beim Löschen des Trainingsplans:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Löschen des Trainingsplans' });
  }
});

app.post('/api/training-plans/:planId/start', async (req, res) => {
  const { planId } = req.params;
  if (!planId)
    return res.status(400).json({ error: 'Ungültige Plan-ID' });
  try {
    await pool.query('UPDATE training_plans SET status = $1 WHERE id = $2', ['aktiv', planId]);
    const exResult = await pool.query(
      'SELECT device_id FROM training_plan_exercises WHERE plan_id = $1 ORDER BY exercise_order',
      [planId]
    );
    const exerciseOrder = exResult.rows.map(row => row.device_id);
    res.json({ message: 'Trainingsplan gestartet', data: { exerciseOrder } });
  } catch (error) {
    console.error('Fehler beim Starten des Trainingsplans:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Starten des Trainingsplans' });
  }
});

// ----------------------
// Coaching-Endpunkte
// ----------------------

app.post('/api/coaching/request/by-membership', async (req, res) => {
  const { coachId, membershipNumber } = req.body;
  if (!coachId || !membershipNumber)
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  try {
    const userResult = await pool.query(
      'SELECT id FROM users WHERE membership_number = $1',
      [membershipNumber]
    );
    if (!userResult.rows.length)
      return res.status(404).json({ error: 'Kein Benutzer mit dieser Mitgliedsnummer gefunden.' });
    const clientId = userResult.rows[0].id;
    const result = await pool.query(
      'INSERT INTO coaching_requests (coach_id, client_id, status, created_at) VALUES ($1, $2, $3, NOW()) RETURNING *',
      [coachId, clientId, 'pending']
    );
    res.json({ message: 'Coaching-Anfrage erfolgreich gesendet', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Senden der Coaching-Anfrage:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Senden der Coaching-Anfrage' });
  }
});

app.get('/api/coaching/request', async (req, res) => {
  const { clientId, coachId } = req.query;
  let query = 'SELECT * FROM coaching_requests';
  let values = [];
  let conditions = [];
  if (clientId) {
    conditions.push(`client_id = $${values.length + 1}`);
    values.push(clientId);
  }
  if (coachId) {
    conditions.push(`coach_id = $${values.length + 1}`);
    values.push(coachId);
  }
  if (conditions.length)
    query += ' WHERE ' + conditions.join(' AND ');
  try {
    const result = await pool.query(query, values);
    res.json({ message: 'Coaching-Anfragen erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Coaching-Anfragen:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Coaching-Anfragen' });
  }
});

app.put('/api/coaching/request/:id', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  if (!status || !['accepted', 'rejected'].includes(status))
    return res.status(400).json({ error: 'Ungültiger Status.' });
  try {
    const result = await pool.query(
      'UPDATE coaching_requests SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );
    if (!result.rows.length)
      return res.status(404).json({ error: 'Coaching-Anfrage nicht gefunden.' });
    res.json({ message: 'Coaching-Anfrage erfolgreich aktualisiert', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Aktualisieren der Coaching-Anfrage:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Aktualisieren der Coaching-Anfrage' });
  }
});

app.get('/api/coach/clients', async (req, res) => {
  const { coachId } = req.query;
  if (!coachId)
    return res.status(400).json({ error: 'Coach-ID fehlt.' });
  try {
    const result = await pool.query(
      'SELECT id, name, email FROM users WHERE coach_id = $1',
      [coachId]
    );
    res.json({ message: 'Klienten erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Klienten:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Klienten' });
  }
});

// ----------------------
// Neuer Endpoint: Eigene Übung erstellen
// ----------------------
app.post('/api/custom_exercise', verifyToken, async (req, res) => {
  const { userId, deviceId, name } = req.body;
  if (!userId || !deviceId || !name) {
    return res.status(400).json({ error: 'Ungültige Eingabedaten.' });
  }
  try {
    const exists = await pool.query(
      'SELECT * FROM custom_exercises WHERE user_id = $1 AND device_id = $2 AND name = $3',
      [userId, deviceId, name]
    );
    if (exists.rows.length) {
      return res.json({ message: 'Custom Exercise bereits vorhanden', data: exists.rows[0] });
    }
    const result = await pool.query(
      'INSERT INTO custom_exercises (user_id, device_id, name, created_at) VALUES ($1, $2, $3, NOW()) RETURNING *',
      [userId, deviceId, name]
    );
    res.json({ message: 'Custom Exercise erfolgreich erstellt', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Erstellen der Custom Exercise:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Erstellen der Custom Exercise' });
  }
});

app.get('/api/custom_exercises', verifyToken, async (req, res) => {
  const { userId, deviceId } = req.query;
  if (!userId || !deviceId) {
    return res.status(400).json({ error: 'userId und deviceId sind erforderlich.' });
  }
  try {
    const result = await pool.query(
      'SELECT * FROM custom_exercises WHERE user_id = $1 AND device_id = $2',
      [userId, deviceId]
    );
    res.json({ message: 'Custom Exercises erfolgreich abgerufen', data: result.rows });
  } catch (error) {
    console.error('Fehler beim Abrufen der Custom Exercises:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Abrufen der Custom Exercises' });
  }
});

app.delete('/api/custom_exercise', verifyToken, async (req, res) => {
  const { userId, deviceId, name } = req.query;
  if (!userId || !deviceId || !name) {
    return res.status(400).json({ error: 'userId, deviceId und name sind erforderlich.' });
  }
  try {
    // Zuerst alle zugehörigen Trainingseinträge löschen
    await pool.query(
      'DELETE FROM training_history WHERE user_id = $1 AND device_id = $2 AND exercise = $3',
      [userId, deviceId, name]
    );
    // Dann den Custom Exercise-Eintrag entfernen
    const result = await pool.query(
      'DELETE FROM custom_exercises WHERE user_id = $1 AND device_id = $2 AND name = $3 RETURNING *',
      [userId, deviceId, name]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Custom Exercise nicht gefunden.' });
    }
    res.json({ message: 'Custom Exercise und zugehöriger Verlauf erfolgreich gelöscht', data: result.rows[0] });
  } catch (error) {
    console.error('Fehler beim Löschen der Custom Exercise:', error.message);
    res.status(500).json({ error: 'Serverfehler beim Löschen der Custom Exercise' });
  }
});

// ----------------------
// Fallback: Alle anderen Routen liefern eine 404-Antwort
// ----------------------
app.get('*', (req, res) => {
  res.status(404).send("Not Found");
});

app.listen(PORT, () => {
  console.log(`Server läuft auf Port ${PORT}`);
});
