import app from '../src/app.js';
import { handle } from 'hono/vercel';

const handler = handle(app);

export const GET = handler;
export const POST = handler;
export const OPTIONS = handler;
