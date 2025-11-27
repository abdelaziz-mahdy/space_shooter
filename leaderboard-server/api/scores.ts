import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '@vercel/postgres';

// Validation constants
const MAX_NAME_LENGTH = 20;
const MIN_NAME_LENGTH = 1;
const MAX_SCORE = 10000000; // 10 million max score
const MAX_WAVE = 1000;
const MAX_KILLS = 100000;
const MAX_TIME_ALIVE = 86400; // 24 hours in seconds
const NAME_REGEX = /^[a-zA-Z0-9\s]+$/;

interface ScoreSubmission {
  playerName: string;
  score: number;
  wave: number;
  kills: number;
  timeAlive: number;
  upgrades: string[];
  weaponUsed?: string;
}

interface LeaderboardEntry {
  id: number;
  player_name: string;
  score: number;
  wave: number;
  kills: number;
  time_alive: number;
  upgrades: string[];
  weapon_used: string | null;
  created_at: string;
  rank?: number;
}

function validateScoreSubmission(data: unknown): { valid: boolean; error?: string; data?: ScoreSubmission } {
  if (!data || typeof data !== 'object') {
    return { valid: false, error: 'Invalid request body' };
  }

  const submission = data as Record<string, unknown>;

  // Validate playerName
  if (typeof submission.playerName !== 'string') {
    return { valid: false, error: 'playerName must be a string' };
  }
  const playerName = submission.playerName.trim();
  if (playerName.length < MIN_NAME_LENGTH || playerName.length > MAX_NAME_LENGTH) {
    return { valid: false, error: `playerName must be between ${MIN_NAME_LENGTH} and ${MAX_NAME_LENGTH} characters` };
  }
  if (!NAME_REGEX.test(playerName)) {
    return { valid: false, error: 'playerName can only contain letters, numbers, and spaces' };
  }

  // Validate score
  if (typeof submission.score !== 'number' || !Number.isInteger(submission.score)) {
    return { valid: false, error: 'score must be an integer' };
  }
  if (submission.score < 0 || submission.score > MAX_SCORE) {
    return { valid: false, error: `score must be between 0 and ${MAX_SCORE}` };
  }

  // Validate wave
  if (typeof submission.wave !== 'number' || !Number.isInteger(submission.wave)) {
    return { valid: false, error: 'wave must be an integer' };
  }
  if (submission.wave < 1 || submission.wave > MAX_WAVE) {
    return { valid: false, error: `wave must be between 1 and ${MAX_WAVE}` };
  }

  // Validate kills
  if (typeof submission.kills !== 'number' || !Number.isInteger(submission.kills)) {
    return { valid: false, error: 'kills must be an integer' };
  }
  if (submission.kills < 0 || submission.kills > MAX_KILLS) {
    return { valid: false, error: `kills must be between 0 and ${MAX_KILLS}` };
  }

  // Validate timeAlive
  if (typeof submission.timeAlive !== 'number') {
    return { valid: false, error: 'timeAlive must be a number' };
  }
  if (submission.timeAlive < 0 || submission.timeAlive > MAX_TIME_ALIVE) {
    return { valid: false, error: `timeAlive must be between 0 and ${MAX_TIME_ALIVE}` };
  }

  // Validate upgrades
  if (!Array.isArray(submission.upgrades)) {
    return { valid: false, error: 'upgrades must be an array' };
  }
  if (!submission.upgrades.every(u => typeof u === 'string')) {
    return { valid: false, error: 'upgrades must be an array of strings' };
  }

  // Validate weaponUsed (optional)
  if (submission.weaponUsed !== undefined && submission.weaponUsed !== null && typeof submission.weaponUsed !== 'string') {
    return { valid: false, error: 'weaponUsed must be a string if provided' };
  }

  return {
    valid: true,
    data: {
      playerName,
      score: submission.score,
      wave: submission.wave,
      kills: submission.kills,
      timeAlive: submission.timeAlive,
      upgrades: submission.upgrades as string[],
      weaponUsed: submission.weaponUsed as string | undefined,
    },
  };
}

async function getScores(limit: number, offset: number): Promise<LeaderboardEntry[]> {
  const result = await sql`
    SELECT
      id,
      player_name,
      score,
      wave,
      kills,
      time_alive,
      upgrades,
      weapon_used,
      created_at,
      RANK() OVER (ORDER BY score DESC) as rank
    FROM leaderboard
    ORDER BY score DESC
    LIMIT ${limit}
    OFFSET ${offset}
  `;

  return result.rows as LeaderboardEntry[];
}

async function submitScore(data: ScoreSubmission): Promise<{ entry: LeaderboardEntry; rank: number }> {
  // Insert the score
  const insertResult = await sql`
    INSERT INTO leaderboard (player_name, score, wave, kills, time_alive, upgrades, weapon_used)
    VALUES (${data.playerName}, ${data.score}, ${data.wave}, ${data.kills}, ${data.timeAlive}, ${JSON.stringify(data.upgrades)}, ${data.weaponUsed || null})
    RETURNING id, player_name, score, wave, kills, time_alive, upgrades, weapon_used, created_at
  `;

  const entry = insertResult.rows[0] as LeaderboardEntry;

  // Get the rank of the inserted score
  const rankResult = await sql`
    SELECT COUNT(*) + 1 as rank
    FROM leaderboard
    WHERE score > ${data.score}
  `;

  const rank = Number(rankResult.rows[0].rank);

  return { entry, rank };
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      // Parse query parameters
      const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 100);
      const offset = Math.max(Number(req.query.offset) || 0, 0);

      const scores = await getScores(limit, offset);

      return res.status(200).json({
        success: true,
        data: scores,
        pagination: {
          limit,
          offset,
          count: scores.length,
        },
      });
    }

    if (req.method === 'POST') {
      const validation = validateScoreSubmission(req.body);

      if (!validation.valid) {
        return res.status(400).json({
          success: false,
          error: validation.error,
        });
      }

      const { entry, rank } = await submitScore(validation.data!);

      return res.status(201).json({
        success: true,
        data: {
          ...entry,
          rank,
        },
      });
    }

    return res.status(405).json({
      success: false,
      error: 'Method not allowed',
    });
  } catch (error) {
    console.error('API Error:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
}
