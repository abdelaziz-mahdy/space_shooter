# Audio System - Quick Start Guide

## What's Been Implemented

A complete audio system is now integrated into the Space Shooter game, including:

- **Background Music**: Automatic looping music with separate tracks for normal gameplay and boss waves
- **Sound Effects**: 10 different sound effects for all game events
- **Audio Controls**: Mute toggle accessible from the settings menu
- **Persistent Settings**: Audio preferences are saved between game sessions
- **Graceful Degradation**: Game works perfectly even without audio files

## Current Status

The system is **fully functional** with placeholder audio files. The game runs without errors and all audio calls are integrated, but actual audio won't play until you add real audio files.

## Adding Real Audio Files (3 Steps)

### Step 1: Get Audio Files

You need these 10 audio files:

**Music (2 files):**
- `gameplay.mp3` - Main background music (loop-friendly, 1-3 minutes)
- `boss.mp3` - Boss battle music (loop-friendly, 1-3 minutes)

**Sound Effects (8 files):**
- `shoot.mp3` - Player weapon fire (short, 0.1-0.3s)
- `explosion.mp3` - Enemy death explosion (punchy, 0.3-0.8s)
- `hit.mp3` - Bullet impact sound (quick, 0.1-0.2s)
- `powerup.mp3` - Power-up collection (bright, 0.3-0.5s)
- `levelup.mp3` - Level up celebration (positive, 0.5-1.0s)
- `button_click.mp3` - UI button click (crisp, 0.05-0.1s)
- `gameover.mp3` - Game over sound (dramatic, 1-2s)
- `boss_appear.mp3` - Boss entrance (intense, 1-2s)

**Free Resources:**
- Music: [Incompetech](https://incompetech.com/), [FreePD](https://freepd.com/)
- SFX: [Freesound](https://freesound.org/), [OpenGameArt](https://opengameart.org/)

### Step 2: Replace Placeholder Files

Copy your audio files to these locations (replacing the empty placeholders):

```
assets/audio/
├── music/
│   ├── gameplay.mp3    <- Replace this
│   └── boss.mp3        <- Replace this
└── sfx/
    ├── shoot.mp3       <- Replace this
    ├── explosion.mp3   <- Replace this
    ├── hit.mp3         <- Replace this
    ├── powerup.mp3     <- Replace this
    ├── levelup.mp3     <- Replace this
    ├── button_click.mp3 <- Replace this
    ├── gameover.mp3    <- Replace this
    └── boss_appear.mp3 <- Replace this
```

**Important:** Keep the exact filenames shown above!

### Step 3: Test

Run the game:
```bash
flutter run
```

You should now hear:
- Background music when the game starts
- Boss music on waves 5, 10, 15, etc.
- Sound effects for all game actions

## Testing Checklist

After adding audio files, verify:

- [ ] Music starts playing when game begins
- [ ] Shooting produces sound (but not too loud)
- [ ] Enemies explode with sound
- [ ] Power-ups make a sound when collected
- [ ] Level up plays a celebration sound
- [ ] All menu buttons click
- [ ] Game over plays dramatic sound
- [ ] Boss waves play special music and entrance sound
- [ ] Mute toggle in settings works
- [ ] Audio settings persist after restarting

## Audio Controls for Users

**In-Game:**
- Press the settings button (gear icon) in top-right
- Toggle "Audio" switch to mute/unmute
- Settings are automatically saved

**For Developers:**
```dart
// Access audio manager from anywhere with gameRef
gameRef.audioManager.playShoot();

// Or from Flutter UI
AudioManager().playButtonClick();

// Toggle mute
await AudioManager().toggleMute();

// Adjust volumes
await AudioManager().setMusicVolume(0.5); // 0.0 to 1.0
await AudioManager().setSfxVolume(0.7);   // 0.0 to 1.0
```

## Troubleshooting

**No sound playing:**
1. Check device volume is up
2. Check in-game mute is off (settings menu)
3. Verify audio files exist and aren't corrupted
4. Check console for "Could not load" warnings

**Audio files too loud/quiet:**
- Normalize your audio files to -3dB to -6dB
- Or adjust in code: `AudioManager().setMusicVolume(0.3)` (lower = quieter)

## File Format Recommendations

**Best Compatibility:**
- Format: MP3 (44.1kHz, 128-192kbps)
- Works on all platforms (web, mobile, desktop)

**Alternative:**
- Format: OGG (may have better performance on some platforms)

**Avoid:**
- WAV (too large)
- FLAC (not supported everywhere)

## Next Steps

After adding audio:

1. **Fine-tune volumes** in `AudioManager._playSfx()` if sounds are too loud/quiet
2. **Add more variety** - different explosion sounds, weapon-specific sounds
3. **Add volume sliders** to settings UI for precise control
4. **Credit your audio** in `assets/audio/README.md`

## Full Documentation

For complete details, see: `AUDIO_SYSTEM_DOCUMENTATION.md`

## Summary

The audio system is **ready to use** - just add your audio files to the `assets/audio/` folder and you're done! No code changes needed.
