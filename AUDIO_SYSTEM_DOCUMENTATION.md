# Audio System Documentation

## Overview

The Space Shooter game now includes a comprehensive audio system that handles background music, sound effects, and audio settings. The system is built using `flame_audio` and provides a centralized, easy-to-use interface for all audio needs.

## Architecture

### AudioManager (Singleton)

Located at: `/lib/managers/audio_manager.dart`

The `AudioManager` is a singleton class that manages all audio in the game. It provides:
- Background music playback with looping
- Sound effect playback
- Mute/unmute functionality
- Volume control
- Persistent settings (saved via SharedPreferences)
- Graceful handling of missing audio files

## Audio Types

### 1. Background Music

**Files:**
- `assets/audio/music/gameplay.mp3` - Normal gameplay background music (loops)
- `assets/audio/music/boss.mp3` - Boss wave background music (loops)

**Usage:**
```dart
// Start normal gameplay music
await audioManager.playMusic(boss: false);

// Start boss music
await audioManager.playMusic(boss: true);

// Stop music
await audioManager.stopMusic();
```

**Integration Points:**
- Game initialization (`SpaceShooterGame.initializeGame()`)
- Boss wave start (`EnemyManager.startNextWave()`)
- Game over (`SpaceShooterGame.gameOver()`)
- Return to menu (`SpaceShooterGame.returnToMainMenu()`)

### 2. Sound Effects

**Files:**
- `assets/audio/sfx/shoot.mp3` - Player shooting
- `assets/audio/sfx/explosion.mp3` - Enemy death/explosion
- `assets/audio/sfx/hit.mp3` - Bullet hitting enemy
- `assets/audio/sfx/powerup.mp3` - Power-up collection
- `assets/audio/sfx/levelup.mp3` - Player level up
- `assets/audio/sfx/button_click.mp3` - UI button clicks
- `assets/audio/sfx/gameover.mp3` - Game over
- `assets/audio/sfx/boss_appear.mp3` - Boss wave start

**Usage:**
```dart
// Play sound effects
audioManager.playShoot();
audioManager.playExplosion();
audioManager.playHit();
audioManager.playPowerUp();
audioManager.playLevelUp();
audioManager.playButtonClick();
audioManager.playGameOver();
audioManager.playBossAppear();
```

**Integration Points:**

| Event | Location | Method |
|-------|----------|--------|
| Player shoots | `PlayerShip.shoot()` | `playShoot()` |
| Enemy dies | `BaseEnemy.die()` | `playExplosion()` |
| Bullet hits enemy | `Bullet.onCollisionStart()` | `playHit()` |
| Power-up collected | `BasePowerUp.onCollisionStart()` | `playPowerUp()` |
| Player levels up | `LevelManager.levelUp()` | `playLevelUp()` |
| Button clicked | Various UI files | `playButtonClick()` |
| Game over | `SpaceShooterGame.gameOver()` | `playGameOver()` |
| Boss appears | `EnemyManager.startNextWave()` | `playBossAppear()` |

## Audio Settings

### Mute Control

The audio system includes a mute toggle that affects both music and sound effects:

```dart
// Toggle mute on/off
await audioManager.toggleMute();

// Check mute status
bool isMuted = audioManager.isMuted;
```

**UI Integration:**
- Settings dialog (`SettingsDialog`) has a switch to toggle mute
- Mute state is saved to SharedPreferences and persists between sessions

### Volume Control

Volume can be controlled separately for music and sound effects:

```dart
// Set music volume (0.0 to 1.0)
await audioManager.setMusicVolume(0.5);

// Set SFX volume (0.0 to 1.0)
await audioManager.setSfxVolume(0.7);

// Get current volumes
double musicVol = audioManager.musicVolume;
double sfxVol = audioManager.sfxVolume;
```

**Default Volumes:**
- Music: 50% (0.5)
- SFX: 70% (0.7)
- Shoot SFX: 35% (0.5 * 0.7 = reduced to prevent ear fatigue)
- Hit SFX: 42% (0.6 * 0.7)

## Initialization

The audio system is initialized when the game loads:

```dart
// In SpaceShooterGame.onLoad()
audioManager = AudioManager();
await audioManager.initialize();
```

The initialization process:
1. Loads saved audio settings from SharedPreferences
2. Precaches all audio files (gracefully handles missing files)
3. Sets up default volumes

## File Management

### Placeholder Files

Currently, the audio system uses empty placeholder files. These allow the game to run without errors while you add real audio files later.

**To add real audio:**
1. Replace the files in `assets/audio/music/` and `assets/audio/sfx/`
2. Keep the same filenames
3. Ensure files are in MP3 or OGG format
4. No code changes needed!

### Missing File Handling

The audio system gracefully handles missing files:
- Precaching logs warnings but doesn't crash
- Playback attempts are silently ignored if files don't exist
- Game continues to function normally

## Audio File Requirements

### Recommended Specifications

**Music:**
- Format: MP3 or OGG
- Sample Rate: 44.1kHz or 48kHz
- Bit Rate: 128-320 kbps
- Channels: Stereo
- Length: 1-3 minutes (will loop)

**Sound Effects:**
- Format: MP3 or OGG
- Sample Rate: 44.1kHz
- Bit Rate: 64-128 kbps
- Channels: Mono or Stereo
- Length: 0.1-2 seconds (short and punchy)

### Free Audio Resources

See `assets/audio/README.md` for links to free audio resources:
- Incompetech (Music)
- FreePD (Music)
- Freesound (SFX)
- OpenGameArt (Music & SFX)
- Zapsplat (SFX)

## Code Examples

### Adding Audio to a New Feature

```dart
// In your component class
class MyNewComponent extends Component with HasGameRef<SpaceShooterGame> {
  void onSomeEvent() {
    // Play a sound effect
    gameRef.audioManager.playExplosion();
  }
}
```

### UI Button with Sound

```dart
ElevatedButton(
  onPressed: () {
    AudioManager().playButtonClick();
    // Your button action here
  },
  child: Text('My Button'),
)
```

### Music Transitions

```dart
// Switch to boss music
await gameRef.audioManager.playMusic(boss: true);

// Switch back to normal music
await gameRef.audioManager.playMusic(boss: false);
```

## Testing

### Test Checklist

- [ ] Background music starts when game begins
- [ ] Boss music plays on wave 5, 10, 15, etc.
- [ ] Shoot sound plays when firing (not too loud)
- [ ] Explosion sound plays when enemies die
- [ ] Hit sound plays when bullets hit enemies
- [ ] Power-up sound plays when collecting power-ups
- [ ] Level up sound plays on level up
- [ ] Button clicks have sound in all menus
- [ ] Game over sound plays at game over
- [ ] Boss appear sound plays at boss wave start
- [ ] Mute toggle works in settings
- [ ] Audio settings persist after restarting game
- [ ] Game doesn't crash with missing audio files

### Manual Testing

1. **Start Game**: Background music should play
2. **Play Until Wave 5**: Boss music should switch automatically
3. **Shoot Enemies**: Hear shoot, hit, and explosion sounds
4. **Collect Power-ups**: Hear power-up sound
5. **Level Up**: Hear level up sound
6. **Open Settings**:
   - Click settings button (should click)
   - Toggle mute (sounds should stop/start)
   - Close settings (should click)
7. **Game Over**: Hear game over sound, music stops
8. **Click Buttons**: All menu buttons should click

## Performance Considerations

### Audio Frequency

Some sounds play very frequently (e.g., shooting). To prevent performance issues:
- Shoot sound is reduced in volume (50% of SFX volume)
- Multiple simultaneous sounds are handled efficiently by flame_audio
- Sound effects are one-shot (not looped)

### Memory Usage

- All audio files are precached on game load
- Cached files remain in memory for fast playback
- Total audio memory usage: ~5-10 MB (depends on file quality)

## Future Enhancements

Potential additions to the audio system:

1. **Volume Sliders**: Add separate sliders for music and SFX in settings
2. **Audio Pools**: Pool frequently-used sounds for better performance
3. **Positional Audio**: 3D audio based on enemy/player position
4. **Dynamic Music**: Music intensity changes based on gameplay
5. **More Variety**: Multiple explosion sounds, weapon-specific sounds
6. **Voice Acting**: Character voice lines or announcements
7. **Ambient Sounds**: Background space ambience, engine hum

## Troubleshooting

### Issue: No audio playing

**Solutions:**
1. Check if audio is muted in settings
2. Check device volume
3. Check if audio files exist in assets folder
4. Run `flutter pub get` to ensure flame_audio is installed
5. Check console for "Could not load" warnings

### Issue: Audio stuttering

**Solutions:**
1. Reduce audio file size/quality
2. Ensure files are precached (check initialization)
3. Check device performance

### Issue: Audio delay

**Solutions:**
1. Use lower latency audio format (OGG over MP3)
2. Reduce file size
3. Precache audio files on load

## API Reference

### AudioManager Methods

```dart
// Initialization
Future<void> initialize()

// Music Control
Future<void> playMusic({bool boss = false})
Future<void> stopMusic()
Future<void> pauseMusic()
Future<void> resumeMusic()

// Sound Effects
Future<void> playShoot()
Future<void> playExplosion()
Future<void> playHit()
Future<void> playPowerUp()
Future<void> playLevelUp()
Future<void> playButtonClick()
Future<void> playGameOver()
Future<void> playBossAppear()

// Settings
Future<void> toggleMute()
Future<void> setMusicVolume(double volume)
Future<void> setSfxVolume(double volume)

// Getters
bool get isMuted
double get musicVolume
double get sfxVolume
bool get isMusicPlaying

// Cleanup
Future<void> dispose()
```

## Credits

Audio system implementation by Claude Code.

Audio assets (when added) should be credited in `assets/audio/README.md`.
