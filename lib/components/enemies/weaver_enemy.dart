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

/// Weaver ("Phantom"): fast, low-HP chaser that weaves side-to-side as it
/// approaches, making it hard to hit with straight fire. Introduced wave 6+.
class WeaverEnemy extends BaseEnemy {
  static const String ID = 'weaver';

  // Weave motion
  static const double weaveFrequency = 7.0; // oscillations (radians/sec)
  static const double weaveAmplitude = 140.0; // lateral speed (px/sec)

  double _weavePhase = 0;
  double _hitFlash = 0;

  WeaverEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 24 + (wave * 2.0),
          speed: 95 + (wave * 2.2), // fast
          lootValue: 2,
          color: Holo.blue,
          size: Vector2(22, 22) * scale,
          contactDamage: 12.0,
        ) {
    // Randomise starting phase so a group doesn't weave in lockstep.
    _weavePhase = Random().nextDouble() * 2 * pi;
  }

  @override
  Future<void> addHitbox() async {
    final verts = <Vector2>[];
    final cx = size.x / 2, cy = size.y / 2;
    for (int i = 0; i < 3; i++) {
      final a = (i * 2 * pi / 3) - pi / 2;
      verts.add(Vector2(cx + cos(a) * size.x / 2, cy + sin(a) * size.y / 2));
    }
    add(PolygonHitbox(verts));
  }

  @override
  void updateMovement(double dt) {
    if (_hitFlash > 0) _hitFlash = max(0, _hitFlash - dt * 4);

    _weavePhase += weaveFrequency * dt;

    final toPlayer = PositionUtil.getDirectionTo(this, player);
    final perpendicular = Vector2(-toPlayer.y, toPlayer.x);
    final lateral = sin(_weavePhase) * weaveAmplitude;

    position += (toPlayer * getEffectiveSpeed() + perpendicular * lateral) * dt;

    // Face the blended travel direction
    angle = atan2(toPlayer.y, toPlayer.x) + pi / 2;
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    _hitFlash = 1.0;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);
  }

  @override
  void renderShape(Canvas canvas) {
    Holo.drawShape(canvas, Holo.polygonPath(size, 3),
        color: Holo.blue, hit: _hitFlash);

    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return WeaverEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    if (wave < 6) return 0.0;
    return 1.2 + (wave * 0.08);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
