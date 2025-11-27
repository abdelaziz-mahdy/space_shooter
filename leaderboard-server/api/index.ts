import { Hono } from 'hono';
import app from '../src/app.js';
import { handle } from 'hono/vercel';

// Create a wrapper app that mounts the main app at /api
// This handles Vercel's routing where /api/index.ts receives requests at /api/*
const wrapper = new Hono();

// Mount at root - the rewrite sends all traffic here
wrapper.route('/', app);

// Also mount at /api for direct /api/* calls
wrapper.route('/api', app);

const handler = handle(wrapper);

export const GET = handler;
export const POST = handler;
export const OPTIONS = handler;
