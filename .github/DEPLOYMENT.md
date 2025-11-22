# GitHub Pages Deployment Setup

This repository is configured to automatically deploy the Flutter web app to GitHub Pages on every push to the `main` branch.

## Setup Instructions

### 1. Enable GitHub Pages

1. Go to your GitHub repository
2. Navigate to **Settings** → **Pages**
3. Under "Build and deployment":
   - **Source**: Select "GitHub Actions"
4. Click **Save**

### 2. Configure Repository Name

The workflow uses `/space_shooter/` as the base href. If your repository has a different name:

1. Open `.github/workflows/deploy.yml`
2. Update line 36: `--base-href "/YOUR_REPO_NAME/"`
3. Commit and push the change

### 3. Trigger Deployment

The workflow triggers automatically on:
- **Push to main branch** - Automatic deployment
- **Manual trigger** - Go to Actions → Deploy to GitHub Pages → Run workflow

### 4. Access Your App

After successful deployment, your app will be available at:
```
https://YOUR_USERNAME.github.io/space_shooter/
```

Replace:
- `YOUR_USERNAME` with your GitHub username
- `space_shooter` with your repository name (if different)

## Workflow Details

- **Build**: Runs on Ubuntu with Flutter stable channel
- **Cache**: Dependencies are cached for faster builds
- **Artifacts**: Build output is uploaded as a Pages artifact
- **Deploy**: Automatically deploys to GitHub Pages

## Troubleshooting

### Build Fails
- Check the Actions tab for error logs
- Verify `pubspec.yaml` dependencies
- Ensure Flutter version compatibility

### 404 Error After Deployment
- Check that base-href matches your repository name
- Verify GitHub Pages is enabled in Settings
- Wait a few minutes for deployment to propagate

### Manual Deployment
If you need to manually trigger deployment:
1. Go to **Actions** tab
2. Select **Deploy to GitHub Pages**
3. Click **Run workflow**
4. Select the `main` branch
5. Click **Run workflow** button

## Local Testing

To test the web build locally before deploying:

```bash
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Then open: http://localhost:8000

## Customization

### Change Flutter Version
Edit `.github/workflows/deploy.yml` line 32:
```yaml
flutter-version: '3.24.0'  # Change to your desired version
```

### Change Trigger Branch
Edit `.github/workflows/deploy.yml` line 5:
```yaml
branches:
  - main  # Change to your desired branch
```
