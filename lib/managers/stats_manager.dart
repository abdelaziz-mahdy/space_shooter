import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

class StatsManager extends Component with HasGameReference<SpaceShooterGame> {
  int enemiesKilled = 0;
  double timeAlive = 0;
  int currentWave = 1;
  int enemiesInWave = 0;
  int enemiesKilledInWave = 0;

  StatsManager({required SpaceShooterGame game});

  void incrementKills() {
    enemiesKilled++;
    enemiesKilledInWave++;
  }

  void startWave(int waveNumber, int enemyCount) {
    print('[StatsManager] startWave called - wave $waveNumber');
    currentWave = waveNumber;
    enemiesInWave = enemyCount;
    enemiesKilledInWave = 0;
  }

  bool isWaveComplete() {
    return enemiesKilledInWave >= enemiesInWave;
  }

  int getEnemiesKilledThisWave() {
    return enemiesKilledInWave;
  }

  @override
  void update(double dt) {
    super.update(dt);

    timeAlive += dt;
  }

  String getTimeAliveFormatted() {
    final minutes = (timeAlive / 60).floor();
    final seconds = (timeAlive % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculate current score (same formula as game over screen)
  int getCurrentScore() {
    final timeAliveSeconds = timeAlive.toInt();
    final wavesCompleted = currentWave - 1; // Current wave not completed yet
    return (enemiesKilled * 10) + (wavesCompleted * 100) + timeAliveSeconds;
  }
}
