# Audio Generation Script

This script procedurally generates all audio files for the Space Shooter game using Python.

## Requirements

- Python 3.7+
- pip (Python package manager)
- ffmpeg (for audio encoding)

## Installation

### 1. Install Python dependencies

```bash
cd scripts
pip install -r requirements.txt
```

### 2. Install ffmpeg

**macOS (using Homebrew):**
```bash
brew install ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install ffmpeg
```

**Windows:**
Download from https://ffmpeg.org/download.html and add to PATH.

## Usage

Run the script from the `scripts` directory:

```bash
python generate_audio.py
```

The script will generate all 10 audio files in the correct directories:
- `assets/audio/music/gameplay.mp3`
- `assets/audio/music/boss.mp3`
- `assets/audio/sfx/*.mp3` (8 sound effect files)

## Generated Audio Files

### Music (Background Loops)

1. **gameplay.mp3** (~2 minutes)
   - Ambient space music
   - Dark chord progression (Cm - Ab - Eb - Bb)
   - 100 BPM
   - Layered: bass line + pad + atmospheric noise

2. **boss.mp3** (~2 minutes)
   - Intense battle music
   - Aggressive progression (Cm - Fm - Gm - Cm)
   - 140 BPM
   - Layered: bass + melody + percussion

### Sound Effects

3. **shoot.mp3** (150ms)
   - Laser sound with frequency sweep (800Hz → 200Hz)
   - Sharp attack, quick decay

4. **explosion.mp3** (400ms)
   - Deep bass rumble (60-90Hz) + white noise burst
   - Long decay for impact

5. **hit.mp3** (120ms)
   - Mid-range punch sound (200Hz square wave)
   - Short and punchy

6. **powerup.mp3** (280ms)
   - Ascending arpeggio (C5 - E5 - G5)
   - Happy, sparkly sound

7. **levelup.mp3** (500ms)
   - Triumphant ascending sequence (C5 - E5 - G5 - C6)
   - Celebratory with harmonics

8. **button_click.mp3** (50ms)
   - Crisp UI click (800Hz + 1200Hz)
   - Very short, immediate feedback

9. **gameover.mp3** (1000ms)
   - Descending sad sequence (C5 - Bb4 - G4 - C4)
   - Dark low-end bass

10. **boss_appear.mp3** (1500ms)
    - Rising ominous rumble + warning beeps
    - Tension-building effect

## How It Works

The script uses:
- **pydub** for audio manipulation and file export
- **numpy** for waveform calculations
- **Procedural synthesis** using basic waveforms:
  - Sine waves (smooth tones)
  - Square waves (harsh, retro tones)
  - Sawtooth waves (rich harmonics)
  - White noise (texture and impact)

Each sound is crafted using:
1. **Waveform generation** at specific frequencies
2. **ADSR envelopes** (Attack, Decay, Sustain, Release)
3. **Layering** multiple sounds
4. **Frequency sweeps** for dynamic effects

## Customization

You can modify the script to adjust:
- Frequencies (change pitch)
- Durations (change length)
- Volume levels (change loudness)
- Waveform types (change timbre)
- Chord progressions (change music feel)
- BPM (change tempo)

## Troubleshooting

**Error: "ffmpeg not found"**
- Install ffmpeg using the instructions above
- Make sure it's in your system PATH

**Error: "No module named 'pydub'"**
- Run `pip install -r requirements.txt`

**Error: "Permission denied"**
- Run with appropriate permissions
- Check that `assets/audio/` directories are writable

## Notes

- The generated audio is procedural and basic, suitable for prototyping
- For production, consider using professionally created audio
- All generated audio is royalty-free (no licensing issues)
- Files are encoded as MP3 at standard quality
