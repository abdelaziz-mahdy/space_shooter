#!/usr/bin/env python3
"""
Audio Generation Script for Space Shooter Game

Generates all required audio files using procedural synthesis.
Requires: numpy, pydub

Install: pip install numpy pydub
"""

import numpy as np
from pydub import AudioSegment
from pydub.generators import Sine, Square, Sawtooth, WhiteNoise
import os


def create_directories():
    """Ensure audio directories exist"""
    os.makedirs('../assets/audio/music', exist_ok=True)
    os.makedirs('../assets/audio/sfx', exist_ok=True)


def generate_sine_wave(frequency, duration_ms, volume=-20):
    """Generate a sine wave tone"""
    return Sine(frequency).to_audio_segment(duration=duration_ms).apply_gain(volume)


def generate_square_wave(frequency, duration_ms, volume=-20):
    """Generate a square wave tone"""
    return Square(frequency).to_audio_segment(duration=duration_ms).apply_gain(volume)


def generate_sawtooth_wave(frequency, duration_ms, volume=-20):
    """Generate a sawtooth wave tone"""
    return Sawtooth(frequency).to_audio_segment(duration=duration_ms).apply_gain(volume)


def generate_white_noise(duration_ms, volume=-30):
    """Generate white noise"""
    return WhiteNoise().to_audio_segment(duration=duration_ms).apply_gain(volume)


def apply_envelope(audio, attack_ms=10, decay_ms=50, sustain_level=0.7, release_ms=100):
    """Apply ADSR envelope to audio"""
    total_length = len(audio)

    # Attack
    if attack_ms > 0:
        audio = audio.fade_in(attack_ms)

    # Release
    if release_ms > 0:
        audio = audio.fade_out(release_ms)

    return audio


def generate_shoot_sound():
    """Generate laser shoot sound effect"""
    print("Generating shoot.mp3...")

    # Fast frequency sweep from high to low (laser sound)
    duration = 150

    # Create frequency sweep
    high_tone = generate_sine_wave(800, 50, volume=-15)
    mid_tone = generate_sine_wave(400, 50, volume=-15)
    low_tone = generate_sine_wave(200, 50, volume=-15)

    # Combine with slight overlap
    shoot = high_tone.append(mid_tone, crossfade=20).append(low_tone, crossfade=20)

    # Add some square wave for texture
    square = generate_square_wave(600, duration, volume=-25)
    shoot = shoot.overlay(square)

    # Sharp attack, quick decay
    shoot = apply_envelope(shoot, attack_ms=5, release_ms=50)

    shoot.export('../assets/audio/sfx/shoot.mp3', format='mp3')


def generate_explosion_sound():
    """Generate explosion sound effect"""
    print("Generating explosion.mp3...")

    # Low rumble + noise burst
    duration = 400

    # Deep bass rumble
    rumble = generate_sine_wave(60, duration, volume=-15)
    rumble = rumble.overlay(generate_sine_wave(90, duration, volume=-18))

    # White noise burst
    noise = generate_white_noise(duration, volume=-20)

    # Combine
    explosion = rumble.overlay(noise)

    # Quick attack, long decay
    explosion = apply_envelope(explosion, attack_ms=10, release_ms=200)

    explosion.export('../assets/audio/sfx/explosion.mp3', format='mp3')


def generate_hit_sound():
    """Generate hit/damage sound effect"""
    print("Generating hit.mp3...")

    # Short punch sound
    duration = 120

    # Mid-range punch
    punch = generate_square_wave(200, duration, volume=-18)

    # Add some noise
    noise = generate_white_noise(duration, volume=-30)

    hit = punch.overlay(noise)
    hit = apply_envelope(hit, attack_ms=5, release_ms=60)

    hit.export('../assets/audio/sfx/hit.mp3', format='mp3')


def generate_powerup_sound():
    """Generate power-up pickup sound effect"""
    print("Generating powerup.mp3...")

    # Ascending arpeggio (happy sound)
    note1 = generate_sine_wave(523, 80, volume=-18)  # C5
    note2 = generate_sine_wave(659, 80, volume=-18)  # E5
    note3 = generate_sine_wave(784, 120, volume=-18)  # G5

    powerup = note1.append(note2, crossfade=20).append(note3, crossfade=20)

    # Add some sparkle with high frequency
    sparkle = generate_sine_wave(1568, 200, volume=-28)
    powerup = powerup.overlay(sparkle)

    powerup = apply_envelope(powerup, attack_ms=5, release_ms=80)

    powerup.export('../assets/audio/sfx/powerup.mp3', format='mp3')


def generate_levelup_sound():
    """Generate level up sound effect"""
    print("Generating levelup.mp3...")

    # Triumphant ascending sequence
    note1 = generate_sine_wave(523, 100, volume=-18)  # C5
    note2 = generate_sine_wave(659, 100, volume=-18)  # E5
    note3 = generate_sine_wave(784, 100, volume=-18)  # G5
    note4 = generate_sine_wave(1047, 200, volume=-18)  # C6

    levelup = (note1.append(note2, crossfade=10)
                    .append(note3, crossfade=10)
                    .append(note4, crossfade=10))

    # Add harmonics
    harmony = generate_sine_wave(1568, 400, volume=-25)
    levelup = levelup.overlay(harmony)

    levelup = apply_envelope(levelup, attack_ms=5, release_ms=150)

    levelup.export('../assets/audio/sfx/levelup.mp3', format='mp3')


def generate_button_click_sound():
    """Generate UI button click sound"""
    print("Generating button_click.mp3...")

    # Short, crisp click
    click = generate_sine_wave(800, 50, volume=-20)
    click = click.overlay(generate_sine_wave(1200, 40, volume=-25))

    click = apply_envelope(click, attack_ms=2, release_ms=30)

    click.export('../assets/audio/sfx/button_click.mp3', format='mp3')


def generate_gameover_sound():
    """Generate game over sound effect"""
    print("Generating gameover.mp3...")

    # Descending sad sequence
    note1 = generate_sine_wave(523, 200, volume=-18)  # C5
    note2 = generate_sine_wave(466, 200, volume=-18)  # Bb4
    note3 = generate_sine_wave(392, 200, volume=-18)  # G4
    note4 = generate_sine_wave(262, 400, volume=-18)  # C4

    gameover = (note1.append(note2, crossfade=20)
                     .append(note3, crossfade=20)
                     .append(note4, crossfade=20))

    # Add some darkness with low frequency
    bass = generate_sine_wave(65, 1000, volume=-25)
    gameover = gameover.overlay(bass)

    gameover = apply_envelope(gameover, attack_ms=10, release_ms=300)

    gameover.export('../assets/audio/sfx/gameover.mp3', format='mp3')


def generate_boss_appear_sound():
    """Generate boss appearance warning sound"""
    print("Generating boss_appear.mp3...")

    # Ominous rising tone with alarm
    duration = 1500

    # Low rumble that rises
    rumble1 = generate_sine_wave(80, 500, volume=-20)
    rumble2 = generate_sine_wave(100, 500, volume=-20)
    rumble3 = generate_sine_wave(120, 500, volume=-20)

    rumble = rumble1.append(rumble2, crossfade=100).append(rumble3, crossfade=100)

    # Warning beep pattern
    beep = generate_square_wave(440, 150, volume=-22)
    silence = AudioSegment.silent(duration=150)
    warning = (beep + silence + beep + silence + beep)

    # Combine
    boss_appear = rumble.overlay(warning)

    boss_appear = apply_envelope(boss_appear, attack_ms=50, release_ms=200)

    boss_appear.export('../assets/audio/sfx/boss_appear.mp3', format='mp3')


def generate_gameplay_music():
    """Generate background gameplay music"""
    print("Generating gameplay.mp3 (this may take a moment)...")

    # Create a simple ambient space music loop
    # Base pattern duration: 8 bars at 120 BPM = 16 seconds
    # We'll make it 2 minutes for variety

    bpm = 100
    beat_duration = int(60000 / bpm)  # ms per beat

    # Chord progression: Cm - Ab - Eb - Bb (dark, spacey)
    # Root notes for bass
    bass_notes = [
        (131, beat_duration * 4),  # C3
        (208, beat_duration * 4),  # Ab3
        (156, beat_duration * 4),  # Eb3
        (233, beat_duration * 4),  # Bb3
    ]

    # Create bass line
    bass = AudioSegment.silent(duration=0)
    for freq, duration in bass_notes:
        note = generate_sine_wave(freq, duration, volume=-25)
        note = apply_envelope(note, attack_ms=50, release_ms=100)
        bass += note

    # Create ambient pad (higher octave)
    pad = AudioSegment.silent(duration=0)
    pad_notes = [
        (262, beat_duration * 4),  # C4
        (415, beat_duration * 4),  # Ab4
        (311, beat_duration * 4),  # Eb4
        (466, beat_duration * 4),  # Bb4
    ]

    for freq, duration in pad_notes:
        note = generate_sine_wave(freq, duration, volume=-30)
        note = apply_envelope(note, attack_ms=200, release_ms=300)
        pad += note

    # Add some atmospheric texture
    texture = generate_white_noise(len(bass), volume=-45)

    # Combine layers
    music = bass.overlay(pad).overlay(texture)

    # Loop it 7-8 times to get ~2 minutes
    full_music = music
    for _ in range(6):
        full_music += music

    # Fade in/out for seamless looping
    full_music = full_music.fade_in(1000).fade_out(2000)

    full_music.export('../assets/audio/music/gameplay.mp3', format='mp3')


def generate_boss_music():
    """Generate boss battle music"""
    print("Generating boss.mp3 (this may take a moment)...")

    # More intense version of gameplay music
    bpm = 140  # Faster tempo
    beat_duration = int(60000 / bpm)

    # More aggressive chord progression: Cm - Fm - Gm - Cm
    bass_notes = [
        (131, beat_duration * 2),  # C3
        (174, beat_duration * 2),  # F3
        (196, beat_duration * 2),  # G3
        (131, beat_duration * 2),  # C3
    ]

    # Create driving bass line
    bass = AudioSegment.silent(duration=0)
    for freq, duration in bass_notes:
        note = generate_square_wave(freq, duration, volume=-22)
        note = apply_envelope(note, attack_ms=10, release_ms=50)
        bass += note

    # Add melody layer (more present than gameplay)
    melody_notes = [
        (523, beat_duration),      # C5
        (587, beat_duration),      # D5
        (659, beat_duration * 2),  # E5
        (523, beat_duration),      # C5
        (698, beat_duration),      # F5
        (784, beat_duration * 2),  # G5
        (659, beat_duration),      # E5
    ]

    melody = AudioSegment.silent(duration=0)
    for freq, duration in melody_notes:
        note = generate_sawtooth_wave(freq, duration, volume=-28)
        note = apply_envelope(note, attack_ms=20, release_ms=80)
        melody += note

    # Add percussion (kick drum simulation)
    kick = generate_sine_wave(60, 100, volume=-20)
    kick = apply_envelope(kick, attack_ms=5, release_ms=80)

    kicks = AudioSegment.silent(duration=0)
    pattern_length = beat_duration * 8
    for i in range(pattern_length // beat_duration):
        if i % 2 == 0:  # Kick on beats 1 and 3
            kicks += kick
        else:
            kicks += AudioSegment.silent(duration=beat_duration)

    # Pad out melody and kicks to match bass length
    while len(melody) < len(bass):
        melody += melody
    melody = melody[:len(bass)]

    while len(kicks) < len(bass):
        kicks += kicks
    kicks = kicks[:len(bass)]

    # Combine all layers
    music = bass.overlay(melody).overlay(kicks)

    # Loop it to get ~2 minutes
    full_music = music
    while len(full_music) < 120000:  # 2 minutes
        full_music += music

    # Trim to exactly 2 minutes
    full_music = full_music[:120000]

    # Fade in/out
    full_music = full_music.fade_in(500).fade_out(2000)

    full_music.export('../assets/audio/music/boss.mp3', format='mp3')


def main():
    """Generate all audio files"""
    print("=" * 60)
    print("Space Shooter Audio Generation Script")
    print("=" * 60)
    print()

    create_directories()

    # Generate all sound effects
    generate_shoot_sound()
    generate_explosion_sound()
    generate_hit_sound()
    generate_powerup_sound()
    generate_levelup_sound()
    generate_button_click_sound()
    generate_gameover_sound()
    generate_boss_appear_sound()

    # Generate music (takes longer)
    generate_gameplay_music()
    generate_boss_music()

    print()
    print("=" * 60)
    print("✓ All audio files generated successfully!")
    print("=" * 60)
    print()
    print("Files created:")
    print("  Music:")
    print("    - assets/audio/music/gameplay.mp3")
    print("    - assets/audio/music/boss.mp3")
    print("  SFX:")
    print("    - assets/audio/sfx/shoot.mp3")
    print("    - assets/audio/sfx/explosion.mp3")
    print("    - assets/audio/sfx/hit.mp3")
    print("    - assets/audio/sfx/powerup.mp3")
    print("    - assets/audio/sfx/levelup.mp3")
    print("    - assets/audio/sfx/button_click.mp3")
    print("    - assets/audio/sfx/gameover.mp3")
    print("    - assets/audio/sfx/boss_appear.mp3")
    print()
    print("You can now test the game with the generated audio!")


if __name__ == '__main__':
    main()
