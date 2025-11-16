import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../components/star_particle.dart';
import '../components/player_ship.dart';

class StarManager extends Component with HasGameRef<SpaceShooterGame> {
  final PlayerShip player;
  final Random random = Random();
  final Set<String> spawnedChunks = {};
  static const double chunkSize = 1000;
  static const int starsPerChunk = 50;

  StarManager({required this.player});

  @override
  void update(double dt) {
    super.update(dt);

    // Get player's current chunk
    final playerChunkX = (player.position.x / chunkSize).floor();
    final playerChunkY = (player.position.y / chunkSize).floor();

    // Spawn stars in surrounding chunks (3x3 grid around player)
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final chunkX = playerChunkX + dx;
        final chunkY = playerChunkY + dy;
        final chunkKey = '$chunkX,$chunkY';

        if (!spawnedChunks.contains(chunkKey)) {
          spawnStarsInChunk(chunkX, chunkY);
          spawnedChunks.add(chunkKey);
        }
      }
    }

    // Clean up far away stars (chunks more than 3 away)
    final toRemove = <String>[];
    for (final chunkKey in spawnedChunks) {
      final parts = chunkKey.split(',');
      final chunkX = int.parse(parts[0]);
      final chunkY = int.parse(parts[1]);

      if ((chunkX - playerChunkX).abs() > 3 ||
          (chunkY - playerChunkY).abs() > 3) {
        toRemove.add(chunkKey);
        removeStarsInChunk(chunkX, chunkY);
      }
    }

    for (final key in toRemove) {
      spawnedChunks.remove(key);
    }
  }

  void spawnStarsInChunk(int chunkX, int chunkY) {
    final baseX = chunkX * chunkSize;
    final baseY = chunkY * chunkSize;

    for (int i = 0; i < starsPerChunk; i++) {
      final star = StarParticle(
        position: Vector2(
          baseX + random.nextDouble() * chunkSize,
          baseY + random.nextDouble() * chunkSize,
        ),
      );
      gameRef.world.add(star);
    }
  }

  void removeStarsInChunk(int chunkX, int chunkY) {
    final baseX = chunkX * chunkSize;
    final baseY = chunkY * chunkSize;

    final stars = gameRef.world.children.whereType<StarParticle>();
    for (final star in stars.toList()) {
      if (star.position.x >= baseX &&
          star.position.x < baseX + chunkSize &&
          star.position.y >= baseY &&
          star.position.y < baseY + chunkSize) {
        star.removeFromParent();
      }
    }
  }
}
