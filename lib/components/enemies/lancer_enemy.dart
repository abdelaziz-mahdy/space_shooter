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

/// Lancer: stalks the player, then telegraphs and dashes in a locked straight
/// line - a dodge-or-get-hit threat. Introduced wave 10+.
///
/// Internal phases (kept as plain string state, not an enum type, since it's a
/// private per-instance FSM rather than an extensible type hierarchy):
///   approach -> charge (telegraph) -> dash -> recover -> approach
class LancerEnemy extends BaseEnemy {
  static const String ID = 'lancer';

  static const double engageDistance = 320; // start charging within this range
  static const double chargeDuration = 0.7; // telegraph time
  static const double dashDuration = 0.45;
  static const double recoverDuration = 1.1;
  static const double dashSpeed = 540;

  static const String _approach = 'approach';
  static const String _charge = 'charge';
  static const String _dash = 'dash';
  static const String _recover = 'recover';

  String _phase = _approach;
  double _phaseTimer = 0;
  Vector2 _dashDir = Vector2(0, 1);
  double _hitFlash = 0;

  LancerEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 55 + (wave * 3.5),
          speed: 55 + (wave * 1.4),
          lootValue: 3,
          color: Holo.purple,
          size: Vector2(26, 26) * scale,
          contactDamage: 20.0,
        );

  @override
  Future<void> addHitbox() async {
    // Diamond (4 sides, vertex-up)
    final verts = <Vector2>[];
    final cx = size.x / 2, cy = size.y / 2;
    for (int i = 0; i < 4; i++) {
      final a = (i * 2 * pi / 4) - pi / 2;
      verts.add(Vector2(cx + cos(a) * size.x / 2, cy + sin(a) * size.y / 2));
    }
    add(PolygonHitbox(verts));
  }

  @override
  void updateMovement(double dt) {
    if (_hitFlash > 0) _hitFlash = max(0, _hitFlash - dt * 4);
    _phaseTimer += dt;

    final toPlayer = PositionUtil.getDirectionTo(this, player);
    final distance = PositionUtil.getDistance(this, player);

    switch (_phase) {
      case _approach:
        position += toPlayer * getEffectiveSpeed() * dt;
        angle = atan2(toPlayer.y, toPlayer.x) + pi / 2;
        if (distance <= engageDistance) {
          _phase = _charge;
          _phaseTimer = 0;
        }
        break;

      case _charge:
        // Brace and aim: lock onto the player's CURRENT position each frame
        // until the dash fires, then commit.
        _dashDir = toPlayer.clone();
        angle = atan2(toPlayer.y, toPlayer.x) + pi / 2;
        // slight backward drift to "wind up"
        position += toPlayer * -getEffectiveSpeed() * 0.3 * dt;
        if (_phaseTimer >= chargeDuration) {
          _phase = _dash;
          _phaseTimer = 0;
        }
        break;

      case _dash:
        position += _dashDir * dashSpeed * dt;
        if (_phaseTimer >= dashDuration) {
          _phase = _recover;
          _phaseTimer = 0;
        }
        break;

      case _recover:
        // brief vulnerable pause
        if (_phaseTimer >= recoverDuration) {
          _phase = _approach;
          _phaseTimer = 0;
        }
        break;
    }
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    _hitFlash = 1.0;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);
  }

  @override
  void renderShape(Canvas canvas) {
    final charging = _phase == _charge;
    final dashing = _phase == _dash;

    // Telegraph: a danger-coloured aim line while charging.
    if (charging) {
      final progress = (_phaseTimer / chargeDuration).clamp(0.0, 1.0);
      final center = Offset(size.x / 2, size.y / 2);
      final aim = Offset(_dashDir.x, _dashDir.y);
      final telePaint = Paint()
        ..color = Holo.danger.withValues(alpha: 0.35 + 0.4 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawLine(
        center,
        center + aim * (size.x * 1.6 + size.x * 2.0 * progress),
        telePaint,
      );
    }

    Holo.drawShape(
      canvas,
      Holo.polygonPath(size, 4),
      color: (charging || dashing) ? Holo.danger : Holo.purple,
      glow: dashing ? 10 : 6,
      hit: _hitFlash,
    );

    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return LancerEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    if (wave < 10) return 0.0;
    return 1.0 + (wave * 0.07);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
