# Audio Assets

This directory contains all audio files for the Space Shooter game.

## Directory Structure

```
assets/audio/
├── music/          # Background music (looping)
│   ├── gameplay.mp3  # Normal gameplay background music
│   └── boss.mp3      # Boss wave background music
└── sfx/            # Sound effects (one-shot)
    ├── shoot.mp3       # Player shooting sound
    ├── explosion.mp3   # Enemy explosion/death sound
    ├── hit.mp3         # Bullet hit sound
    ├── powerup.mp3     # Power-up collection sound
    ├── levelup.mp3     # Level up sound
    ├── button_click.mp3 # UI button click sound
    ├── gameover.mp3    # Game over sound
    └── boss_appear.mp3 # Boss appearance sound
```

## Audio File Requirements

- **Format**: MP3 (recommended) or OGG
- **Sample Rate**: 44.1kHz or 48kHz
- **Bit Rate**: 128-320 kbps for music, 64-128 kbps for SFX
- **Channels**: Stereo for music, Mono or Stereo for SFX

## Adding Audio Files

The audio system is designed to handle missing files gracefully. Currently, placeholder files exist. To add real audio:

1. Replace the placeholder `.mp3` files with actual audio files
2. Keep the same filenames
3. Ensure files are properly licensed for use in your game

## Audio Credits

Add attribution for any audio assets here:

- Music: [Add credits here]
- Sound Effects: [Add credits here]

## Free Audio Resources

If you need free audio assets, check out:

- **Music**:
  - [Incompetech](https://incompetech.com/) (Creative Commons)
  - [FreePD](https://freepd.com/) (Public Domain)
  - [OpenGameArt](https://opengameart.org/)

- **Sound Effects**:
  - [Freesound](https://freesound.org/)
  - [OpenGameArt](https://opengameart.org/)
  - [Zapsplat](https://www.zapsplat.com/) (Free with attribution)
