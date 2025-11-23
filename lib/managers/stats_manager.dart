import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

class StatsManager extends Component with HasGameRef<SpaceShooterGame> {
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

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    timeAlive += dt;
  }

  String getTimeAliveFormatted() {
    final minutes = (timeAlive / 60).floor();
    final seconds = (timeAlive % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
