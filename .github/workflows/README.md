# Claude Code Workflows

This directory contains GitHub Actions workflows for automated code review and fixes using Claude Code.

## Workflows

### 1. `claude-code-review.yml` - Automated Code Review + Auto-Fix
**Trigger**: When a PR is opened or updated

**What it does**:
- Automatically reviews pull requests
- Checks code quality, best practices, bugs, performance, and security
- Leaves detailed review comments on the PR with severity indicators
- **AUTOMATICALLY creates a fix PR** if any issues can be fixed
- Follows project guidelines from `CLAUDE.md`

**The Auto-Fix Magic**:
When Claude finds fixable issues, it automatically:
1. Creates a new branch: `fix/auto-fix-pr-{NUMBER}`
2. Applies ALL fixes following CLAUDE.md principles
3. Updates version and changelog if needed
4. Creates a new PR with the fixes
5. Links it back to the original PR

**Configuration**:
- Uncomment the `paths` section to only review specific file types
- Uncomment the `if` condition to filter by PR author (e.g., only external contributors)

---

### 2. `claude.yml` - Interactive Claude Assistant
**Trigger**: When someone mentions `@claude` in:
- Issue comments
- PR comments
- PR review comments
- New issues

**What it does**:
- Responds to `@claude` mentions
- Can perform various tasks based on instructions
- Can read CI results and other PR information

**Usage Example**:
```
@claude please update the PR description with a summary of changes
```

---

### 3. `claude-auto-fix.yml` - Automatic Code Fixes (NEW!)
**Trigger**:
- When a PR review contains `@claude-fix`
- Manual trigger via GitHub Actions UI

**What it does**:
1. Reads the original PR and all review comments
2. Analyzes the feedback and identifies suggested changes
3. Applies the fixes following `CLAUDE.md` guidelines
4. Creates a new branch: `fix/auto-fix-pr-{NUMBER}`
5. Commits the changes
6. Creates a new PR with the fixes
7. Links it back to the original PR

**How to use**:

**Method 1: From Review Comments**
1. Claude reviews your PR and leaves comments
2. Add a new review comment containing `@claude-fix`
3. The workflow automatically creates a fix PR

**Method 2: Manual Trigger**
1. Go to Actions → "Claude Auto-Fix from Review"
2. Click "Run workflow"
3. Enter the PR number
4. Click "Run workflow"

**Example Flow**:
```
1. You create PR #123
2. claude-code-review.yml reviews it and comments with suggestions
3. You add a review comment: "@claude-fix please apply these changes"
4. claude-auto-fix.yml creates PR #124 with fixes
5. PR #124 references PR #123
```

---

## Setup Requirements

### Required Secrets
Add `CLAUDE_CODE_OAUTH_TOKEN` to your repository secrets:
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `CLAUDE_CODE_OAUTH_TOKEN`
4. Value: Your Claude Code OAuth token
5. Click "Add secret"

### Required Permissions
The workflows need these permissions (already configured):
- `contents: write` - To create branches and commits
- `pull-requests: write` - To create and comment on PRs
- `issues: read` - To read issue/PR content
- `actions: read` - To read CI results
- `id-token: write` - For OAuth authentication

---

## Configuration Options

### Customize Review Focus
Edit `claude-code-review.yml` line 43-48 to change what Claude reviews:
```yaml
Please review this pull request and provide feedback on:
- Code quality and best practices
- Potential bugs or issues
- Performance considerations
- Security concerns
- Test coverage
- [Add your custom criteria here]
```

### Filter by File Types
Uncomment and customize the `paths` section in `claude-code-review.yml`:
```yaml
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
  - "assets/**/*.json"
```

### Filter by Author
Uncomment and customize the `if` condition in `claude-code-review.yml`:
```yaml
if: |
  github.event.pull_request.user.login == 'external-contributor' ||
  github.event.pull_request.author_association == 'FIRST_TIME_CONTRIBUTOR'
```

---

## Important Notes

### Version & Changelog Updates
When Claude applies fixes that are client-facing:
- It MUST update `pubspec.yaml` version
- It MUST add an entry to `assets/changelog.json`
- Both files must be updated in the same commit
- See `CLAUDE.md` for detailed guidelines

### Project Guidelines
All Claude workflows use the coding principles defined in `CLAUDE.md`:
- Avoid code duplication
- Use classes instead of enums
- Percentage-based responsive design
- Single source of truth for data
- Proper inheritance and composition

### Safety Measures
The auto-fix workflow:
- Only fixes issues explicitly mentioned in reviews
- Follows project coding standards
- Creates a separate PR (doesn't modify the original)
- Allows human review before merging
- Asks for clarification if unsure

---

## Troubleshooting

### Workflow not triggering?
- Check that `CLAUDE_CODE_OAUTH_TOKEN` is set
- Verify repository permissions
- Check workflow file syntax with `gh workflow view`

### Claude not finding files?
- Ensure `fetch-depth: 0` is set for full git history
- Check file paths are correct

### Need to debug?
Add this step before the Claude action:
```yaml
- name: Debug Info
  run: |
    echo "Event: ${{ github.event_name }}"
    echo "PR Number: ${{ github.event.pull_request.number }}"
    gh pr view ${{ github.event.pull_request.number }}
```

---

## Examples

### Example 1: Review Specific Files Only
```yaml
# In claude-code-review.yml
paths:
  - "lib/**/*.dart"
  - "!lib/**/*_test.dart"  # Exclude test files
```

### Example 2: Custom Review Instructions
```yaml
# In claude-code-review.yml
prompt: |
  Review this Dart/Flutter PR focusing on:
  - Flame engine best practices
  - Performance in game loop
  - Memory leaks in components
  - Proper pause handling
```

### Example 3: Trigger Auto-Fix with Custom Instructions
Add a review comment:
```
@claude-fix

Please apply these fixes:
1. Fix the responsive layout issue in main_menu.dart
2. Update the missile upgrade logic as suggested
3. Add version bump and changelog entry

Make sure to follow the percentage-based responsive design pattern from CLAUDE.md.
```

---

## Resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Project Guidelines](../../CLAUDE.md)
