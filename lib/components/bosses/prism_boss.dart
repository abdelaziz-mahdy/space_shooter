import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../../rendering/holographic.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';

/// Aegis Prism - a holographic boss for the wave 55+ rotation.
///
/// - Orbits the player at range, rotating wireframe prism body
/// - Fires rotating rings of holo-bolts
/// - Periodically summons Weaver adds (capped)
/// - Enrages below 50% HP: faster, denser bolt rings
class PrismBoss extends BaseEnemy {
  static const String ID = 'prism_boss'; // must contain 'boss' for boss selection

  static const double orbitDistance = 330;
  static const double orbitSpeed = 55;

  static const double burstInterval = 2.2;
  static const double summonInterval = 7.0;
  static const int maxAdds = 4;
  static const double bulletSpeed = 165;
  static const double bulletDamage = 18;

  double _spin = 0;
  double _pulse = 0;
  double _ringOffset = 0;
  double _burstTimer = 0;
  double _summonTimer = 0;
  double _hitFlash = 0;
  final List<BaseEnemy> _adds = [];

  PrismBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 600 + (wave * 80),
          speed: 30 + (wave * 0.6),
          lootValue: 55,
          color: Holo.purple,
          size: Vector2(68, 68) * scale,
          contactDamage: 32.0,
        );

  bool get isEnraged => health < maxHealth * 0.5;

  @override
  Future<void> addHitbox() async {
    // Hexagon hitbox covering the prism body
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
    _spin += dt * (isEnraged ? 1.6 : 0.9);
    _pulse += dt * 4;

    // Orbit the player
    final distance = PositionUtil.getDistance(this, player);
    final toPlayer = PositionUtil.getDirectionTo(this, player);
    if (distance < orbitDistance - 50) {
      position += toPlayer * -getEffectiveSpeed() * dt;
    } else if (distance > orbitDistance + 50) {
      position += toPlayer * getEffectiveSpeed() * dt;
    } else {
      final perpendicular = Vector2(-toPlayer.y, toPlayer.x);
      position += perpendicular * orbitSpeed * dt;
    }

    // Bolt rings
    _burstTimer += dt;
    final interval = isEnraged ? burstInterval * 0.6 : burstInterval;
    if (_burstTimer >= interval) {
      _fireRing(isEnraged ? 14 : 10);
      _burstTimer = 0;
    }

    // Summon adds
    _adds.removeWhere((a) => a.isRemoved);
    _summonTimer += dt;
    if (_summonTimer >= summonInterval && _adds.length < maxAdds) {
      _summonAdds();
      _summonTimer = 0;
    }
  }

  void _fireRing(int count) {
    for (int i = 0; i < count; i++) {
      final a = _ringOffset + i * 2 * pi / count;
      final dir = Vector2(cos(a), sin(a));
      final bullet = EnemyBullet(
        position: position.clone(),
        direction: dir,
        damage: bulletDamage,
        speed: bulletSpeed,
      );
      bullet.size = Vector2.all(11);
      game.world.add(bullet);
    }
    _ringOffset += 0.4; // rotate each successive ring for a spiral feel
  }

  void _summonAdds() {
    final random = Random();
    final count = min(2, maxAdds - _adds.length);
    for (int i = 0; i < count; i++) {
      final offset = Vector2(
        (random.nextDouble() - 0.5) * size.x * 3,
        (random.nextDouble() - 0.5) * size.x * 3,
      );
      final add = EnemyFactory.create(
        'weaver', // Weaver adds (string id avoids an import cycle)
        player,
        wave,
        position.clone() + offset,
        scale: game.entityScale,
      );
      _adds.add(add);
      game.world.add(add);
    }
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    _hitFlash = 1.0;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);
  }

  Path _ring(int sides, double radius, double rot) {
    final p = Path();
    final cx = size.x / 2, cy = size.y / 2;
    for (int i = 0; i < sides; i++) {
      final a = i * 2 * pi / sides + rot;
      final x = cx + cos(a) * radius;
      final y = cy + sin(a) * radius;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  @override
  void renderShape(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final bodyColor = isEnraged ? Holo.danger : Holo.purple;

    // Rotating targeting brackets
    Holo.reticle(canvas, center, size.x / 2 + 12, rotation: _spin * 0.6);

    // Outer prism (hexagon) + counter-rotating inner triangle
    Holo.drawShape(canvas, _ring(6, size.x * 0.5, -pi / 2 + _spin),
        color: bodyColor, strokeWidth: 2.0, glow: 8, hit: _hitFlash);
    Holo.drawShape(canvas, _ring(3, size.x * 0.30, -pi / 2 - _spin * 1.3),
        color: Holo.teal, strokeWidth: 1.6, glow: 6, scanlines: false, hit: _hitFlash);

    // Pulsing core
    Holo.drawCircle(canvas, center, size.x * 0.10 * (0.85 + 0.15 * sin(_pulse)),
        color: Holo.white, glow: 7, fillOpacity: 0.4);

    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return PrismBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) => 0.0; // joins via the 55+ bossPool

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
