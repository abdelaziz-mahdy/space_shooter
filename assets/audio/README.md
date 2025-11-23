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

The audio system is designed to handle missing files gracefully. Current files are procedurally generated. To replace with custom audio:

1. Replace the `.mp3` files with your own audio files
2. Keep the same filenames
3. Ensure files are properly licensed for use in your game

### Regenerating Audio Files

To regenerate the procedurally-generated audio files:

```bash
cd scripts
pip install -r requirements.txt
python3 generate_audio.py
```

See `scripts/README.md` for customization options.

## Audio Credits

All audio files were procedurally generated using Python:

- **Music**: Generated using synthesized waveforms (sine, square, sawtooth waves)
- **Sound Effects**: Generated using procedural synthesis with ADSR envelopes
- **Generator**: `scripts/generate_audio.py` (see scripts/README.md for details)
- **License**: Public domain / Royalty-free (procedurally generated)

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
