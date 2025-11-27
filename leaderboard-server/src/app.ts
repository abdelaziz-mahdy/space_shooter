import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { query } from './db.js';

const app = new Hono();

// Middleware
app.use('/*', cors());

// Validation constants
const MAX_NAME_LENGTH = 20;
const MIN_NAME_LENGTH = 1;
const MAX_SCORE = 10000000;
const NAME_REGEX = /^[a-zA-Z0-9\s]+$/;

// Landing page
app.get('/', (c) => {
  return c.html(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Space Shooter Leaderboard API</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: linear-gradient(135deg, #0a0a1a 0%, #1a1a3a 100%);
          color: #fff;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .container {
          text-align: center;
          padding: 2rem;
          max-width: 600px;
        }
        h1 {
          font-size: 2.5rem;
          margin-bottom: 0.5rem;
          background: linear-gradient(90deg, #00ffff, #ff00ff);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }
        .subtitle {
          color: #888;
          margin-bottom: 2rem;
        }
        .endpoints {
          background: rgba(255,255,255,0.05);
          border-radius: 12px;
          padding: 1.5rem;
          text-align: left;
          margin-bottom: 2rem;
        }
        .endpoints h2 {
          font-size: 1rem;
          color: #00ffff;
          margin-bottom: 1rem;
        }
        .endpoint {
          margin-bottom: 1rem;
          padding: 0.75rem;
          background: rgba(0,0,0,0.3);
          border-radius: 8px;
        }
        .method {
          display: inline-block;
          padding: 0.25rem 0.5rem;
          border-radius: 4px;
          font-size: 0.75rem;
          font-weight: bold;
          margin-right: 0.5rem;
        }
        .get { background: #00aa55; }
        .post { background: #0066ff; }
        .path { color: #ffaa00; font-family: monospace; }
        .desc { color: #aaa; font-size: 0.85rem; margin-top: 0.5rem; }
        .game-link {
          display: inline-block;
          padding: 0.75rem 1.5rem;
          background: linear-gradient(90deg, #00ffff, #ff00ff);
          color: #000;
          text-decoration: none;
          border-radius: 8px;
          font-weight: bold;
          transition: transform 0.2s;
        }
        .game-link:hover { transform: scale(1.05); }
        .status {
          margin-top: 2rem;
          color: #00ff00;
          font-size: 0.85rem;
        }
        .status::before {
          content: '●';
          margin-right: 0.5rem;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Space Shooter</h1>
        <p class="subtitle">Global Leaderboard API</p>

        <div class="endpoints">
          <h2>API Endpoints</h2>
          <div class="endpoint">
            <span class="method get">GET</span>
            <span class="path">/health</span>
            <p class="desc">Health check endpoint</p>
          </div>
          <div class="endpoint">
            <span class="method get">GET</span>
            <span class="path">/scores</span>
            <p class="desc">Get top scores (supports ?limit=N&offset=N)</p>
          </div>
          <div class="endpoint">
            <span class="method post">POST</span>
            <span class="path">/scores</span>
            <p class="desc">Submit a new score</p>
          </div>
        </div>

        <a href="https://abdelaziz-mahdy.github.io/space_shooter/" class="game-link">
          🎮 Play the Game
        </a>

        <p class="status">API Online</p>
      </div>
    </body>
    </html>
  `);
});

// Health check
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'space-shooter-leaderboard',
  });
});

// Get top scores
app.get('/scores', async (c) => {
  try {
    const limitParam = c.req.query('limit');
    const offsetParam = c.req.query('offset');
    const limit = Math.min(Math.max(parseInt(limitParam || '50'), 1), 100);
    const offset = Math.max(parseInt(offsetParam || '0'), 0);

    const result = await query(
      `SELECT
        id,
        player_name,
        score,
        wave,
        kills,
        time_alive,
        upgrades,
        weapon_used,
        created_at
      FROM leaderboard
      ORDER BY score DESC
      LIMIT $1
      OFFSET $2`,
      [limit, offset]
    );

    // Get total count
    const countResult = await query('SELECT COUNT(*) as total FROM leaderboard');
    const total = parseInt(countResult.rows[0].total);

    // Add rank to each entry
    const entries = result.rows.map((row, index) => ({
      id: row.id,
      playerName: row.player_name,
      score: row.score,
      wave: row.wave,
      kills: row.kills,
      timeAlive: parseFloat(row.time_alive),
      upgrades: row.upgrades || [],
      weaponUsed: row.weapon_used,
      createdAt: row.created_at,
      rank: offset + index + 1,
    }));

    return c.json({
      success: true,
      entries,
      total,
      limit,
      offset,
    });
  } catch (error) {
    console.error('Error fetching scores:', error);
    return c.json({
      success: false,
      error: 'Failed to fetch leaderboard',
    }, 500);
  }
});

// Submit a new score
app.post('/scores', async (c) => {
  try {
    const body = await c.req.json();
    const { playerName, score, wave, kills, timeAlive, upgrades, weaponUsed } = body;

    // Validate player name
    if (!playerName || typeof playerName !== 'string') {
      return c.json({
        success: false,
        error: 'Player name is required',
      }, 400);
    }

    const trimmedName = playerName.trim();
    if (trimmedName.length < MIN_NAME_LENGTH || trimmedName.length > MAX_NAME_LENGTH) {
      return c.json({
        success: false,
        error: `Player name must be between ${MIN_NAME_LENGTH} and ${MAX_NAME_LENGTH} characters`,
      }, 400);
    }

    if (!NAME_REGEX.test(trimmedName)) {
      return c.json({
        success: false,
        error: 'Player name can only contain letters, numbers, and spaces',
      }, 400);
    }

    // Validate score
    if (typeof score !== 'number' || score < 0 || score > MAX_SCORE) {
      return c.json({
        success: false,
        error: 'Invalid score',
      }, 400);
    }

    // Validate other fields
    if (typeof wave !== 'number' || wave < 0) {
      return c.json({
        success: false,
        error: 'Invalid wave number',
      }, 400);
    }

    if (typeof kills !== 'number' || kills < 0) {
      return c.json({
        success: false,
        error: 'Invalid kills count',
      }, 400);
    }

    if (typeof timeAlive !== 'number' || timeAlive < 0) {
      return c.json({
        success: false,
        error: 'Invalid time alive',
      }, 400);
    }

    // Sanitize upgrades array
    const sanitizedUpgrades = Array.isArray(upgrades)
      ? upgrades.filter((u): u is string => typeof u === 'string').slice(0, 50)
      : [];

    // Sanitize weapon
    const sanitizedWeapon = typeof weaponUsed === 'string' ? weaponUsed.slice(0, 50) : null;

    // Insert into database
    const result = await query(
      `INSERT INTO leaderboard (player_name, score, wave, kills, time_alive, upgrades, weapon_used)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, created_at`,
      [trimmedName, score, wave, kills, timeAlive, sanitizedUpgrades, sanitizedWeapon]
    );

    // Get rank of new entry
    const rankResult = await query(
      'SELECT COUNT(*) + 1 as rank FROM leaderboard WHERE score > $1',
      [score]
    );

    const newEntry = {
      id: result.rows[0].id,
      playerName: trimmedName,
      score,
      wave,
      kills,
      timeAlive,
      upgrades: sanitizedUpgrades,
      weaponUsed: sanitizedWeapon,
      createdAt: result.rows[0].created_at,
      rank: parseInt(rankResult.rows[0].rank),
    };

    return c.json({
      success: true,
      entry: newEntry,
    }, 201);
  } catch (error) {
    console.error('Error submitting score:', error);
    return c.json({
      success: false,
      error: 'Failed to submit score',
    }, 500);
  }
});

export default app;
