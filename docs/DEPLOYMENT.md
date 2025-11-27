# Deployment Guide

This guide covers deploying both the Flutter game and the leaderboard backend.

## Table of Contents
- [Game Deployment (GitHub Pages)](#game-deployment-github-pages)
- [Leaderboard Server Deployment (Vercel)](#leaderboard-server-deployment-vercel)
- [Database Setup (Neon)](#database-setup-neon)
- [Environment Configuration](#environment-configuration)

---

## Game Deployment (GitHub Pages)

The game is automatically deployed to GitHub Pages via GitHub Actions when you push to the `main` branch.

### Automatic Deployment

1. **Fork or clone the repository**

2. **Enable GitHub Pages**
   - Go to your repo → Settings → Pages
   - Source: "GitHub Actions"

3. **Push to main branch**
   - The workflow at `.github/workflows/deploy.yml` will automatically:
     - Build the Flutter web app with WASM
     - Deploy to GitHub Pages

4. **Access your game**
   - URL: `https://<your-username>.github.io/space_shooter/`

### Manual Deployment

```bash
# Build the web app
flutter build web --release --wasm --base-href "/space_shooter/"

# The built files are in build/web/
# Upload to any static hosting (Netlify, Vercel, Firebase Hosting, etc.)
```

---

## Leaderboard Server Deployment (Vercel)

The leaderboard backend uses Vercel serverless functions with a Neon PostgreSQL database.

### Prerequisites
- [Vercel account](https://vercel.com) (free tier works)
- [Neon account](https://neon.tech) (free tier works)
- Node.js 18+ installed locally

### Step 1: Deploy to Vercel

```bash
# Navigate to the server directory
cd leaderboard-server

# Install dependencies
npm install

# Install Vercel CLI (if not already installed)
npm install -g vercel

# Login to Vercel
vercel login

# Deploy (follow the prompts)
vercel

# For production deployment
vercel --prod
```

During deployment, Vercel will ask:
- **Set up and deploy?** Yes
- **Which scope?** Select your account
- **Link to existing project?** No (create new)
- **Project name?** `space-shooter-leaderboard` (or your preference)
- **Directory?** `./` (current directory)

### Step 2: Note Your Deployment URL

After deployment, you'll get a URL like:
```
https://space-shooter-leaderboard.vercel.app
```

Your API endpoints will be:
- Health check: `https://space-shooter-leaderboard.vercel.app/api/health`
- Scores: `https://space-shooter-leaderboard.vercel.app/api/scores`

---

## Database Setup (Neon)

### Step 1: Create a Neon Project

1. Go to [neon.tech](https://neon.tech) and sign up/login
2. Click "Create Project"
3. Choose a name (e.g., `space-shooter-db`)
4. Select a region close to your users
5. Click "Create Project"

### Step 2: Get Connection String

1. In your Neon dashboard, go to your project
2. Click "Connection Details"
3. Copy the connection string (looks like):
   ```
   postgres://user:password@ep-xxx.region.aws.neon.tech/neondb?sslmode=require
   ```

### Step 3: Add Environment Variables to Vercel

1. Go to your Vercel project dashboard
2. Navigate to **Settings → Environment Variables**
3. Add these variables:

   | Name | Value | Description |
   |------|-------|-------------|
   | `DATABASE_URL` | Your Neon connection string | PostgreSQL connection |
   | `MIGRATION_SECRET` | A random secret string | Protects the migration endpoint |

   For `MIGRATION_SECRET`, generate a random string (e.g., `openssl rand -hex 32`)

4. Set **Environments** to: Production, Preview, Development
5. Click "Save"

### Step 4: Run Database Migration

The server includes a built-in migration endpoint that creates the necessary tables.

1. **Redeploy to pick up environment variables:**
   ```bash
   cd leaderboard-server
   vercel --prod
   ```

2. **Run the migration** (replace with your values):
   ```bash
   curl "https://your-project.vercel.app/migrate?secret=YOUR_MIGRATION_SECRET"
   ```

3. **Expected response:**
   ```json
   {"success":true,"message":"Migration completed successfully"}
   ```

This creates the `leaderboard` table and indexes. You only need to run this once.

### Step 5: Test the API

```bash
# Health check
curl https://your-project.vercel.app/api/health

# Should return:
# {"status":"ok","timestamp":"...","service":"space-shooter-leaderboard"}

# Get top scores
curl https://your-project.vercel.app/api/scores

# Should return:
# {"success":true,"entries":[],"total":0}
```

---

## Environment Configuration

### GitHub Actions (CI/CD)

To enable leaderboard in the deployed game:

1. Go to your GitHub repo → **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add:
   - **Name:** `LEADERBOARD_API_URL`
   - **Value:** `https://your-project.vercel.app/api`

The GitHub Actions workflow will automatically inject this into the build.

### Local Development

Create a `.env` file in the project root:

```env
LEADERBOARD_API_URL=https://your-project.vercel.app/api
```

**Important:** Never commit `.env` files! They're already in `.gitignore`.

---

## Troubleshooting

### "Failed to load leaderboard"
- Check if `LEADERBOARD_API_URL` is set correctly
- Verify the API is responding: `curl <your-api-url>/health`
- Check Vercel logs for errors

### "Database connection failed"
- Verify `POSTGRES_URL` is set in Vercel environment variables
- Check if the Neon project is active (free tier may pause after inactivity)
- Ensure the connection string includes `?sslmode=require`

### "CORS errors in browser"
- The API includes CORS headers by default
- If issues persist, check `vercel.json` for proper header configuration

### Scores not saving
- Check browser console for error messages
- Verify player name meets requirements (1-20 chars, alphanumeric + spaces)
- Check Vercel function logs for backend errors

---

## Cost Considerations

### Free Tier Limits

**Vercel (Hobby Plan):**
- 100GB bandwidth/month
- Serverless function invocations: 100,000/month
- Plenty for a hobby game project

**Neon (Free Tier):**
- 0.5 GB storage
- 3 GB data transfer/month
- Compute auto-suspends after 5 minutes of inactivity
- Perfect for leaderboards (wake-up time ~1-2 seconds)

### Scaling Up

If your game becomes popular:
- Vercel Pro: $20/month for more bandwidth and functions
- Neon Pro: Starting at $19/month for always-on compute

---

## Security Notes

1. **No authentication** - The API is public. Anyone can submit scores.
2. **Input validation** - Server validates all inputs (name length, score limits)
3. **Rate limiting** - Consider adding rate limiting for production
4. **Environment variables** - Never expose database credentials in code

For a hobby project, this setup is fine. For a commercial game, consider:
- Adding authentication (Firebase Auth, Auth0)
- Implementing rate limiting
- Adding anti-cheat measures
- Using a CDN for the game assets
