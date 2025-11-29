# Claude Auto-Review & Auto-Fix - Quick Start

## 🎯 What Happens Automatically

```
YOU CREATE A PR
       ↓
CLAUDE REVIEWS IT (automatic)
       ↓
CLAUDE CREATES FIX PR (automatic, if issues found)
       ↓
YOU REVIEW & MERGE THE FIX
```

## ✨ The Magic

**You do this:**
1. Create a PR with your changes
2. Push it to GitHub

**Claude automatically does this:**
1. Reviews your PR within seconds
2. Posts a comment with findings (🔴 Critical, 🟡 Important, 🔵 Suggestion)
3. **Commits fixes directly to your PR** (same branch, no extra PRs!)
4. Stops automatically to avoid infinite loops

**You do this:**
1. Review the updated PR with Claude's fixes
2. Merge when ready!

## 📊 Real Example

### You Create PR #50:
```
Title: "Add missile upgrade system"
Files: lib/components/weapons/missile.dart
```

### Claude Reviews & Fixes (all automatic!):
```
Comment on PR #50:
🔍 Claude Code Review:
🔴 Critical: Using enum MissileType instead of classes (line 45)
🟡 Important: Hardcoded damage values (line 67)
🔵 Suggestion: Missing changelog entry

✅ Automated fix PR created: #51
```

### Claude Updates PR #50 (same PR!):
```
New commit added to PR #50:
"fix: Apply review suggestions

✅ Converted MissileType enum to class hierarchy
✅ Changed hardcoded damage to configurable properties
✅ Updated version to 0.3.1
✅ Added changelog entry

🤖 Auto-applied by Claude Code Review"

Files changed in this commit:
- lib/components/weapons/missile.dart
- pubspec.yaml
- assets/changelog.json
```

### You Review PR #50:
- ✅ Looks good? Merge it!
- ❌ Need changes? Push more commits or comment with `@claude please adjust X`

## 🔧 What Gets Fixed Automatically

Claude will automatically fix:

✅ **Enums → Classes**
```dart
// Before (your code)
enum PowerUpType { health, shield, damage }

// After (Claude's fix)
abstract class PowerUpType { ... }
class HealthPowerUp extends PowerUpType { ... }
```

✅ **Hardcoded Values → Percentages**
```dart
// Before (your code)
final width = 280.0;
final spacing = 30.0;

// After (Claude's fix)
final width = size.x * 0.35;  // 35% of screen width
final spacing = size.x * 0.04; // 4% of screen width
```

✅ **Missing Version/Changelog**
```yaml
# pubspec.yaml - Before
version: 0.3.0

# pubspec.yaml - After (Claude bumps it)
version: 0.3.1
```

```json
// changelog.json - Claude adds entry
{
  "version": "0.3.1",
  "title": "Missile System Improvements",
  "date": "2025-11-29",
  "sections": [...]
}
```

✅ **Code Quality Issues**
- Switch statements → Polymorphism
- Duplicated code → Shared base classes
- Wrong coordinate systems
- Missing pause handling

## 🚫 What Claude WON'T Auto-Fix

Claude will **review but NOT auto-fix**:
- Complex architectural changes that need discussion
- Ambiguous requirements
- Breaking changes
- Things it's uncertain about

For these, Claude will:
- Leave detailed comments explaining the issue
- Suggest approaches
- Wait for your input

## 🎮 How to Use

### Option 1: Let It Run Automatically (Recommended!)
1. Create your PR
2. Wait ~30 seconds
3. Check for Claude's review comment
4. Check if Claude committed fixes to your PR
5. Review the changes and merge when ready!

**Note:** Claude only runs once per human commit to avoid infinite loops. If Claude commits fixes, it won't review its own changes.

### Option 2: Manual Trigger (for existing PRs)
1. Go to **Actions** → **"Claude Auto-Fix from Review"**
2. Click **"Run workflow"**
3. Enter PR number
4. Click **"Run workflow"**

### Option 3: Ask Claude Directly
1. Comment on any PR: `@claude please review this`
2. Claude will respond and perform tasks

## 📋 Requirements Checklist

Before using, make sure:
- ✅ `CLAUDE_CODE_OAUTH_TOKEN` is set in repository secrets
- ✅ Workflows are enabled in repository settings
- ✅ Claude has write access to repository

## 🐛 Troubleshooting

### "Claude didn't commit fixes to my PR"
**Possible reasons:**
- No fixable issues found (only suggestions that need manual review)
- Claude wasn't certain about the fix
- Error in applying fixes (check workflow logs)
- The latest commit was made by Claude (prevents infinite loop)

**What to do:**
- Check the review comment - Claude explains why
- Review suggestions manually
- Push a new commit if you want Claude to review again

### "Claude's fixes have issues"
**What to do:**
- Don't merge the PR!
- Push a new commit with corrections
- Or revert Claude's commit: `git revert HEAD && git push`
- Or comment: `@claude please adjust X and Y`

### "Workflow failed"
**What to do:**
- Check Actions tab for error logs
- Verify `CLAUDE_CODE_OAUTH_TOKEN` is set
- Check repository permissions

## 💡 Pro Tips

1. **Check both PRs**: Always review both your original PR and Claude's fix PR
2. **Merge order**: Usually merge the fix PR first, then close/update your original PR
3. **Learn from fixes**: Claude follows CLAUDE.md - use the fixes to learn the patterns!
4. **Trust but verify**: Claude is smart but not perfect - always review the changes
5. **Iterate**: If Claude's fix isn't quite right, just ask it to adjust with `@claude`

## 🔗 More Info

- Full workflow details: [workflows/README.md](workflows/README.md)
- Visual diagram: [CLAUDE_WORKFLOW.md](CLAUDE_WORKFLOW.md)
- Coding principles: [../../CLAUDE.md](../../CLAUDE.md)

---

**Remember:** This is all automatic! Just create your PR and let Claude do the heavy lifting. 🚀
