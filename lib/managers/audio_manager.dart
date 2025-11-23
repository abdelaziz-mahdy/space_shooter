import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized audio management system for the game
/// Handles background music, sound effects, and audio settings
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio settings
  bool _isMuted = false;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  // Music state
  bool _isMusicPlaying = false;
  String? _currentMusic;

  // Preferences key
  static const String _mutedKey = 'audio_muted';
  static const String _musicVolumeKey = 'music_volume';
  static const String _sfxVolumeKey = 'sfx_volume';

  // Audio file paths
  static const String _bgmNormal = 'music/gameplay.mp3';
  static const String _bgmBoss = 'music/boss.mp3';
  static const String _sfxShoot = 'sfx/shoot.mp3';
  static const String _sfxExplosion = 'sfx/explosion.mp3';
  static const String _sfxHit = 'sfx/hit.mp3';
  static const String _sfxPowerUp = 'sfx/powerup.mp3';
  static const String _sfxLevelUp = 'sfx/levelup.mp3';
  static const String _sfxButtonClick = 'sfx/button_click.mp3';
  static const String _sfxGameOver = 'sfx/gameover.mp3';
  static const String _sfxBossAppear = 'sfx/boss_appear.mp3';

  /// Initialize the audio system
  /// Loads audio settings from preferences and precaches audio files
  Future<void> initialize() async {
    print('[AudioManager] Initializing...');

    // Load saved settings
    await _loadSettings();

    // Precache all audio files (gracefully handle missing files)
    await _precacheAudio();

    print('[AudioManager] Initialized - Muted: $_isMuted, Music: $_musicVolume, SFX: $_sfxVolume');
  }

  /// Load audio settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_mutedKey) ?? false;
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.5;
      _sfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 0.7;
    } catch (e) {
      print('[AudioManager] Error loading settings: $e');
    }
  }

  /// Save audio settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutedKey, _isMuted);
      await prefs.setDouble(_musicVolumeKey, _musicVolume);
      await prefs.setDouble(_sfxVolumeKey, _sfxVolume);
    } catch (e) {
      print('[AudioManager] Error saving settings: $e');
    }
  }

  /// Precache all audio files
  /// Handles missing files gracefully by catching exceptions
  Future<void> _precacheAudio() async {
    // List of all audio files to precache
    final audioFiles = [
      _bgmNormal,
      _bgmBoss,
      _sfxShoot,
      _sfxExplosion,
      _sfxHit,
      _sfxPowerUp,
      _sfxLevelUp,
      _sfxButtonClick,
      _sfxGameOver,
      _sfxBossAppear,
    ];

    for (final file in audioFiles) {
      try {
        // Try to load the file - if it doesn't exist, just log and continue
        await FlameAudio.audioCache.load(file);
        print('[AudioManager] Precached: $file');
      } catch (e) {
        print('[AudioManager] Could not load $file (file may not exist yet): $e');
      }
    }
  }

  // === Music Methods ===

  /// Play background music (loops automatically)
  Future<void> playMusic({bool boss = false}) async {
    if (_isMuted) return;

    final musicFile = boss ? _bgmBoss : _bgmNormal;

    // Don't restart if already playing this track
    if (_isMusicPlaying && _currentMusic == musicFile) return;

    try {
      // Stop current music if playing
      if (_isMusicPlaying) {
        await FlameAudio.bgm.stop();
      }

      // Play new music
      await FlameAudio.bgm.play(musicFile, volume: _musicVolume);
      _isMusicPlaying = true;
      _currentMusic = musicFile;
      print('[AudioManager] Playing music: $musicFile');
    } catch (e) {
      print('[AudioManager] Error playing music: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
      _isMusicPlaying = false;
      _currentMusic = null;
      print('[AudioManager] Music stopped');
    } catch (e) {
      print('[AudioManager] Error stopping music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    try {
      await FlameAudio.bgm.pause();
      print('[AudioManager] Music paused');
    } catch (e) {
      print('[AudioManager] Error pausing music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (_isMuted) return;

    try {
      await FlameAudio.bgm.resume();
      print('[AudioManager] Music resumed');
    } catch (e) {
      print('[AudioManager] Error resuming music: $e');
    }
  }

  // === Sound Effect Methods ===

  /// Play a sound effect
  Future<void> _playSfx(String file, {double? volume}) async {
    if (_isMuted) return;

    try {
      await FlameAudio.play(file, volume: volume ?? _sfxVolume);
    } catch (e) {
      // Silently handle missing sound files
      // print('[AudioManager] Could not play $file: $e');
    }
  }

  /// Player shooting sound
  Future<void> playShoot() async {
    await _playSfx(_sfxShoot, volume: _sfxVolume * 0.5); // Quieter since it plays frequently
  }

  /// Enemy explosion/death sound
  Future<void> playExplosion() async {
    await _playSfx(_sfxExplosion);
  }

  /// Bullet hit sound
  Future<void> playHit() async {
    await _playSfx(_sfxHit, volume: _sfxVolume * 0.6);
  }

  /// Power-up collection sound
  Future<void> playPowerUp() async {
    await _playSfx(_sfxPowerUp);
  }

  /// Level up sound
  Future<void> playLevelUp() async {
    await _playSfx(_sfxLevelUp);
  }

  /// Button click sound
  Future<void> playButtonClick() async {
    await _playSfx(_sfxButtonClick, volume: _sfxVolume * 0.8);
  }

  /// Game over sound
  Future<void> playGameOver() async {
    await _playSfx(_sfxGameOver);
  }

  /// Boss appearance sound
  Future<void> playBossAppear() async {
    await _playSfx(_sfxBossAppear);
  }

  // === Settings Methods ===

  /// Toggle mute on/off
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;

    if (_isMuted) {
      await FlameAudio.bgm.pause();
    } else {
      if (_currentMusic != null) {
        await FlameAudio.bgm.resume();
      }
    }

    await _saveSettings();
    print('[AudioManager] Mute toggled: $_isMuted');
  }

  /// Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);

    if (_isMusicPlaying && !_isMuted) {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    }

    await _saveSettings();
  }

  /// Set sound effects volume (0.0 to 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  // === Getters ===

  bool get isMuted => _isMuted;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMusicPlaying => _isMusicPlaying;

  /// Dispose audio resources
  Future<void> dispose() async {
    await FlameAudio.bgm.stop();
    FlameAudio.bgm.dispose();
  }
}
