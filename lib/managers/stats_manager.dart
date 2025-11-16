import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

class StatsManager extends Component with HasGameRef<SpaceShooterGame> {
  int enemiesKilled = 0;
  double timeAlive = 0;
  int currentWave = 1;
  int enemiesInWave = 0;
  int enemiesKilledInWave = 0;
  double waveTime = 0; // Time remaining in current wave (countdown)
  double waveDuration = 120.0; // Total duration for wave

  StatsManager({required SpaceShooterGame game});

  void incrementKills() {
    enemiesKilled++;
    enemiesKilledInWave++;
  }

  void startWave(int waveNumber, int enemyCount, double duration) {
    print('[StatsManager] startWave called - wave $waveNumber, resetting timer to $duration');
    currentWave = waveNumber;
    enemiesInWave = enemyCount;
    enemiesKilledInWave = 0;
    waveDuration = duration;
    waveTime = duration; // Start countdown from duration
  }

  bool isWaveComplete() {
    return enemiesKilledInWave >= enemiesInWave;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused for upgrade
    if (gameRef.isPausedForUpgrade) return;

    timeAlive += dt;
    waveTime -= dt; // Countdown
    if (waveTime < 0) waveTime = 0;
  }

  String getTimeAliveFormatted() {
    final minutes = (timeAlive / 60).floor();
    final seconds = (timeAlive % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getWaveTimeFormatted() {
    final minutes = (waveTime / 60).floor();
    final seconds = (waveTime % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
