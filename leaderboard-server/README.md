# Space Shooter Leaderboard Server

Vercel serverless API for the Space Shooter game global leaderboard.

## Setup

### 1. Deploy to Vercel

1. Go to [vercel.com](https://vercel.com) and sign in
2. Import this directory as a new project
3. Vercel will automatically detect the configuration

### 2. Add Neon PostgreSQL Database

1. In your Vercel project dashboard, go to **Storage**
2. Click **Create Database** and select **Neon Serverless Postgres**
3. Follow the prompts to create the database
4. Vercel will automatically inject the `DATABASE_URL` environment variable

### 3. Run Database Migration

In the Neon dashboard SQL editor, run:

```sql
CREATE TABLE leaderboard (
  id SERIAL PRIMARY KEY,
  player_name VARCHAR(50) NOT NULL,
  score INT NOT NULL,
  wave INT NOT NULL,
  kills INT NOT NULL,
  time_alive FLOAT NOT NULL,
  upgrades JSONB NOT NULL,
  weapon_used VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_leaderboard_score ON leaderboard(score DESC);
CREATE INDEX idx_leaderboard_created ON leaderboard(created_at DESC);
```

## API Endpoints

### GET /api/health

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "service": "space-shooter-leaderboard"
}
```

### GET /api/scores

Fetch leaderboard entries.

**Query Parameters:**
- `limit` (optional): Number of entries to return (1-100, default: 50)
- `offset` (optional): Offset for pagination (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "player_name": "Player1",
      "score": 10000,
      "wave": 15,
      "kills": 100,
      "time_alive": 300.5,
      "upgrades": ["damage", "fire_rate"],
      "weapon_used": "pulse_cannon",
      "created_at": "2024-01-01T00:00:00.000Z",
      "rank": 1
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "count": 1
  }
}
```

### POST /api/scores

Submit a new score.

**Request Body:**
```json
{
  "playerName": "Player1",
  "score": 10000,
  "wave": 15,
  "kills": 100,
  "timeAlive": 300.5,
  "upgrades": ["damage", "fire_rate"],
  "weaponUsed": "pulse_cannon"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "player_name": "Player1",
    "score": 10000,
    "wave": 15,
    "kills": 100,
    "time_alive": 300.5,
    "upgrades": ["damage", "fire_rate"],
    "weapon_used": "pulse_cannon",
    "created_at": "2024-01-01T00:00:00.000Z",
    "rank": 1
  }
}
```

## Local Development

```bash
npm install
npm run dev
```

This requires the [Vercel CLI](https://vercel.com/docs/cli) to be installed.
