import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../../rendering/holographic.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Splinter: a chaser that fractures into two smaller copies when destroyed,
/// until it runs out of splits. Creates swarm pressure. Introduced wave 8+.
class SplinterEnemy extends BaseEnemy {
  static const String ID = 'splinter';

  /// Splits left before this becomes terminal. A freshly-spawned Splinter
  /// starts at [initialSplits]; children get one fewer. 2 -> spawns 2 -> each
  /// spawns 2 (1 -> 2 -> 4, terminal at 0).
  static const int initialSplits = 2;

  final int splitsRemaining;
  final double spawnScale;
  double _hitFlash = 0;

  SplinterEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
    this.splitsRemaining = initialSplits,
  })  : spawnScale = scale,
        super(
          position: position,
          player: player,
          wave: wave,
          // Bigger (more splits left) = tankier
          health: (16 + (wave * 1.4)) * (0.6 + 0.25 * splitsRemaining),
          speed: 60 + (wave * 1.6),
          lootValue: splitsRemaining > 0 ? 1 : 2,
          color: Holo.teal,
          size: Vector2.all(14.0 + 7.0 * splitsRemaining) * scale,
          contactDamage: 10.0,
        );

  @override
  Future<void> addHitbox() async {
    // Hexagon
    final verts = <Vector2>[];
    final cx = size.x / 2, cy = size.y / 2;
    for (int i = 0; i < 6; i++) {
      final a = (i * 2 * pi / 6) - pi / 2;
      verts.add(Vector2(cx + cos(a) * size.x / 2, cy + sin(a) * size.y / 2));
    }
    add(PolygonHitbox(verts));
  }

  @override
  void updateMovement(double dt) {
    if (_hitFlash > 0) _hitFlash = max(0, _hitFlash - dt * 4);
    final toPlayer = PositionUtil.getDirectionTo(this, player);
    position += toPlayer * getEffectiveSpeed() * dt;
    angle = atan2(toPlayer.y, toPlayer.x) + pi / 2;
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    _hitFlash = 1.0;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);
  }

  @override
  void onDeath() {
    if (splitsRemaining <= 0) return;

    // Spawn two smaller copies offset to either side of the death position.
    final random = Random();
    for (int i = 0; i < 2; i++) {
      final offsetAngle = random.nextDouble() * 2 * pi;
      final offset = Vector2(cos(offsetAngle), sin(offsetAngle)) * (size.x * 0.6);
      final child = SplinterEnemy(
        position: position.clone() + offset,
        player: player,
        wave: wave,
        scale: spawnScale,
        splitsRemaining: splitsRemaining - 1,
      );
      game.world.add(child);
    }
  }

  @override
  void renderShape(Canvas canvas) {
    Holo.drawShape(canvas, Holo.polygonPath(size, 6),
        color: Holo.teal, hit: _hitFlash);

    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return SplinterEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    if (wave < 8) return 0.0;
    return 0.9 + (wave * 0.06);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
