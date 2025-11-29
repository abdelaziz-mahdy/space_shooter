# Claude Code Workflow Diagram

## Automated Review → Auto-Fix Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                          │
└─────────────────────────────────────────────────────────────────────┘

1. Developer creates PR #123
   │
   ├─> "fix: Update missile upgrade logic"
   │
   └─> Changes: lib/components/weapons/missile.dart

                            ↓

┌─────────────────────────────────────────────────────────────────────┐
│              CLAUDE CODE REVIEW + AUTO-FIX (AUTOMATIC!)             │
│                   (claude-code-review.yml)                          │
└─────────────────────────────────────────────────────────────────────┘

2. Claude automatically reviews PR #123
   │
   ├─> Checks code quality
   ├─> Identifies bugs
   ├─> Checks against CLAUDE.md guidelines
   │
3. Claude posts review comment:
   │
   "🔍 Claude Code Review:
    🔴 Critical: Using enum instead of classes (lib/weapons.dart:45)
    🟡 Important: Hardcoded values instead of percentages (lib/ui/menu.dart:120)
    🔵 Suggestion: Missing version/changelog update"
   │
4. Claude IMMEDIATELY applies fixes (same workflow run!)
   │
   ├─> Creates branch: fix/auto-fix-pr-123
   ├─> Fixes enum → classes
   ├─> Fixes hardcoded → percentages
   ├─> Updates pubspec.yaml version
   ├─> Updates assets/changelog.json
   │
5. Claude creates PR #124
   │
   ├─> Title: "Auto-fix: Address review issues from PR #123"
   ├─> Body: "🤖 Automated fixes based on code review
   │          Fixes issues found in #123
   │          - Converted MissileType enum to class hierarchy
   │          - Changed hardcoded spacing to percentages
   │          - Added changelog entry for v0.3.1"
   │
6. Claude comments on ORIGINAL PR #123:
   │
   └─> "✅ Automated fix PR created: #124"
   │
   └─> Both PRs ready for review!

                            ↓

┌─────────────────────────────────────────────────────────────────────┐
│                        HUMAN REVIEW                                 │
└─────────────────────────────────────────────────────────────────────┘

7. Developer reviews PR #124
   │
   ├─> ✅ Fixes look good → Merge PR #124
   ├─> ❌ Needs changes → Comment with @claude to adjust
   │
   └─> Merge → Close PR #123 or merge both
```

---

## Alternative Flow: Manual Trigger

```
Developer wants to fix PR #123 manually:

1. Go to GitHub Actions
   │
2. Click "Claude Auto-Fix from Review"
   │
3. Click "Run workflow"
   │
4. Enter PR number: 123
   │
5. Click "Run workflow"
   │
   └─> Same auto-fix process as above!
```

---

## Interactive Assistant Flow

```
Developer needs help with a PR:

1. Add comment on PR #123:
   "@claude please update the PR description with a summary"

   ↓

2. Claude reads the PR

   ↓

3. Claude updates PR description

   ↓

4. Claude comments: "✅ Updated PR description"
```

---

## File Change Example

### Before Claude Review:
```dart
// lib/components/weapons/missile.dart (lines 45-60)

enum MissileType { basic, homing, cluster }

class MissileWeapon extends Weapon {
  final MissileType type;

  @override
  void fire() {
    double damage;
    switch (type) {
      case MissileType.basic:
        damage = 50.0;
        break;
      case MissileType.homing:
        damage = 75.0;
        break;
    }
    // ... fire logic
  }
}
```

### After Claude Auto-Fix:
```dart
// lib/components/weapons/missile.dart (lines 45-75)

abstract class MissileType {
  double get baseDamage;
  String get description;
  Color get trailColor;
  void applyBehavior(Missile missile);
}

class BasicMissile extends MissileType {
  @override
  double get baseDamage => 50.0;

  @override
  String get description => 'Standard explosive missile';

  @override
  Color get trailColor => const Color(0xFFFF6600);

  @override
  void applyBehavior(Missile missile) {
    // Basic straight trajectory
  }
}

class HomingMissile extends MissileType {
  @override
  double get baseDamage => 75.0;

  @override
  String get description => 'Tracks nearest enemy';

  @override
  Color get trailColor => const Color(0xFF00FFFF);

  @override
  void applyBehavior(Missile missile) {
    // Homing logic
  }
}

class MissileWeapon extends Weapon {
  final MissileType missileType;

  @override
  void fire() {
    final damage = missileType.baseDamage;
    final missile = Missile(missileType);
    // ... fire logic
  }
}
```

**Changes Made:**
- ✅ Replaced enum with class hierarchy
- ✅ Encapsulated behavior in each missile type
- ✅ Removed switch statement
- ✅ Each type owns its data (damage, color, description)
- ✅ Follows CLAUDE.md principles

---

## Summary

| Workflow | Trigger | Purpose | Output |
|----------|---------|---------|--------|
| `claude-code-review.yml` | PR opened/updated | Automated review + auto-fix | Review comment + Fix PR automatically created |
| `claude-auto-fix.yml` | `@claude-fix` comment or manual | Apply fixes on-demand | New PR with fixes |
| `claude.yml` | `@claude` mention | Interactive assistant | Performs requested tasks |

**Key Benefits:**
- 🚀 **Fully Automatic**: Reviews AND fixes happen without any manual trigger
- 🔧 **Instant Fixes**: Fix PR created in the same workflow run as the review
- 📋 **Follows Guidelines**: Adheres to CLAUDE.md principles
- 🔗 **Traceable**: Links PRs and comments for full context
- 👁️ **Human-in-the-loop**: Final review before merging
- ⚡ **Zero Wait Time**: No need to trigger fixes separately
