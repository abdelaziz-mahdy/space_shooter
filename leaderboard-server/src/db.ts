import pg from 'pg';

const { Pool } = pg;

// Use DATABASE_URL or POSTGRES_URL environment variable
const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;

if (!connectionString) {
  console.warn('Warning: No database connection string found. Set DATABASE_URL or POSTGRES_URL environment variable.');
}

export const pool = new Pool({
  connectionString,
  ssl: connectionString?.includes('neon.tech') ? { rejectUnauthorized: false } : undefined,
});

export async function query(text: string, params?: any[]) {
  const client = await pool.connect();
  try {
    const result = await client.query(text, params);
    return result;
  } finally {
    client.release();
  }
}
