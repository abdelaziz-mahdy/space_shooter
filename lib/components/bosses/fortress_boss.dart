import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../../game/space_shooter_game.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';

/// The Fortress Boss - Wave 30
/// - Large square (110x110) with 4 corner turrets
/// - Gray (#808080) with red turrets
/// - Health: 600 + (wave * 85) - highest health
/// - Speed: 20 + (wave * 0.3) - slowest
/// - Contact damage: 40
/// - Loot: 45
///
/// Movement:
/// - Barely moves, positions at top center of screen
/// - Slow body rotation
///
/// Attack:
/// - 4 corner turrets fire independently (0.8s interval, 2-shot burst, aim at player)
/// - Central body fires 8-way spread every 2.5s
/// - Deploys orbital mines (8 max, orbit around boss, 12s rotation)
/// - Mines deal 25 damage, explode on contact, can be destroyed (20 HP each)
/// - New mine every 4 seconds
class FortressBoss extends BaseEnemy {
  static const String ID = 'fortress_boss';

  // Movement constants
  static const double targetY = 150.0; // Position near top of screen
  static const double rotationSpeed = 0.5; // Slow rotation

  // Attack constants
  static const double centralFireInterval = 2.5;
  static const double turretFireInterval = 0.8;
  static const int turretBurstCount = 2;
  static const double turretBurstDelay = 0.15;
  static const double bulletSpeed = 180.0;
  static const double bulletDamage = 22.0;

  // Mine constants
  static const int maxOrbitalMines = 8;
  static const double mineSpawnInterval = 4.0;
  static const double mineOrbitRadius = 100.0;
  static const double mineOrbitSpeed = pi / 6; // 12 seconds per rotation

  // State tracking
  double centralFireTimer = 0;
  final List<_FortressTurret> turrets = [];
  final List<_OrbitalMine> mines = [];
  double mineSpawnTimer = 0;
  double mineOrbitAngle = 0;

  FortressBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 600 + (wave * 85),
          speed: 20 + (wave * 0.3),
          lootValue: 45,
          color: const Color(0xFF808080), // Gray
          size: Vector2(110, 110) * scale,
          contactDamage: 40.0,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create 4 corner turrets
    final turretOffsets = [
      Vector2(-size.x / 2, -size.y / 2), // Top-left
      Vector2(size.x / 2, -size.y / 2), // Top-right
      Vector2(size.x / 2, size.y / 2), // Bottom-right
      Vector2(-size.x / 2, size.y / 2), // Bottom-left
    ];

    for (final offset in turretOffsets) {
      final turret = _FortressTurret(
        parent: this,
        offset: offset,
      );
      turrets.add(turret);
      add(turret);
    }
  }

  @override
  Future<void> addHitbox() async {
    // Square hitbox
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final halfSize = size.x / 2;

    final points = <Vector2>[
      Vector2(centerX - halfSize, centerY - halfSize),
      Vector2(centerX + halfSize, centerY - halfSize),
      Vector2(centerX + halfSize, centerY + halfSize),
      Vector2(centerX - halfSize, centerY + halfSize),
    ];

    add(PolygonHitbox(points));
  }

  @override
  void updateMovement(double dt) {
    // Move to top center position if not there yet
    if (position.y > targetY) {
      position.y -= speed * dt;
    }

    // Slow rotation
    angle += rotationSpeed * dt;

    // Update mine orbit angle
    mineOrbitAngle += mineOrbitSpeed * dt;
    if (mineOrbitAngle > 2 * pi) {
      mineOrbitAngle -= 2 * pi;
    }

    // Update mines
    _updateMines(dt);

    // Spawn new mines
    mineSpawnTimer += dt;
    if (mineSpawnTimer >= mineSpawnInterval && mines.length < maxOrbitalMines) {
      _spawnMine();
      mineSpawnTimer = 0;
    }

    // Central body attack
    centralFireTimer += dt;
    if (centralFireTimer >= centralFireInterval) {
      _fireCentralSpread();
      centralFireTimer = 0;
    }
  }

  void _fireCentralSpread() {
    // Fire 8-way spread (cardinal + diagonal)
    final directions = [
      Vector2(1, 0), // Right
      Vector2(1, 1), // Bottom-right
      Vector2(0, 1), // Down
      Vector2(-1, 1), // Bottom-left
      Vector2(-1, 0), // Left
      Vector2(-1, -1), // Top-left
      Vector2(0, -1), // Up
      Vector2(1, -1), // Top-right
    ];

    for (final dir in directions) {
      final normalizedDir = dir.normalized();
      final bullet = EnemyBullet(
        position: position.clone(),
        direction: normalizedDir,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      gameRef.world.add(bullet);
    }

    print('[FortressBoss] Fired 8-way spread from central body');
  }

  void _spawnMine() {
    // Calculate position on orbit
    final angle = (mines.length * 2 * pi / maxOrbitalMines) + mineOrbitAngle;
    final offset = Vector2(
      cos(angle) * mineOrbitRadius,
      sin(angle) * mineOrbitRadius,
    );

    final mine = _OrbitalMine(
      parent: this,
      orbitIndex: mines.length,
    );

    mines.add(mine);
    add(mine);

    print('[FortressBoss] Spawned mine ${mines.length}/$maxOrbitalMines');
  }

  void _updateMines(double dt) {
    // Remove destroyed mines
    mines.removeWhere((mine) => !mine.isMounted);
  }

  @override
  void renderShape(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw main fortress body (square)
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bodyStroke = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.x,
        height: size.y,
      ),
      bodyPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.x,
        height: size.y,
      ),
      bodyStroke,
    );

    // Draw central core
    final corePaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      15,
      corePaint,
    );

    // Draw boss indicator (red outline)
    final bossPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.x / 2 + 10,
      bossPaint,
    );

    // Draw status effects and health bar
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return FortressBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 30 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 30) return 100.0;
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}

/// Turret component for the Fortress Boss
class _FortressTurret extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final FortressBoss parent;
  final Vector2 offset;

  double fireTimer = 0;
  int burstShot = 0;
  double burstTimer = 0;
  bool isFiring = false;

  _FortressTurret({
    required this.parent,
    required this.offset,
  }) : super(
          position: offset,
          size: Vector2(20, 20),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused) return;

    // Update fire timer
    fireTimer += dt;

    if (isFiring) {
      // Handle burst firing
      burstTimer += dt;
      if (burstTimer >= FortressBoss.turretBurstDelay) {
        burstTimer = 0;
        _fireBullet();
        burstShot++;

        if (burstShot >= FortressBoss.turretBurstCount) {
          isFiring = false;
          burstShot = 0;
        }
      }
    } else if (fireTimer >= FortressBoss.turretFireInterval) {
      // Start new burst
      fireTimer = 0;
      isFiring = true;
      burstShot = 0;
      burstTimer = 0;
    }
  }

  void _fireBullet() {
    // Fire toward player
    final turretWorldPos = parent.position + offset;
    final directionToPlayer = (parent.player.position - turretWorldPos).normalized();

    final bullet = EnemyBullet(
      position: turretWorldPos,
      direction: directionToPlayer,
      damage: FortressBoss.bulletDamage,
      speed: FortressBoss.bulletSpeed,
    );

    gameRef.world.add(bullet);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw turret (small red square)
    final turretPaint = Paint()
      ..color = const Color(0xFFFF0000) // Red
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: size.y,
      ),
      turretPaint,
    );

    // Draw turret barrel
    final barrelPaint = Paint()
      ..color = const Color(0xFF880000)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 2, 0, 4, size.y / 2),
      barrelPaint,
    );
  }
}

/// Orbital mine component for the Fortress Boss
class _OrbitalMine extends PositionComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  final FortressBoss parent;
  final int orbitIndex;

  double health = 20.0;
  bool isExploding = false;

  _OrbitalMine({
    required this.parent,
    required this.orbitIndex,
  }) : super(
          size: Vector2(16, 16),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add hitbox
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused || isExploding) return;

    // Update position to orbit around parent
    final angle = (orbitIndex * 2 * pi / FortressBoss.maxOrbitalMines) +
        parent.mineOrbitAngle;
    final offset = Vector2(
      cos(angle) * FortressBoss.mineOrbitRadius,
      sin(angle) * FortressBoss.mineOrbitRadius,
    );

    position = offset;
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      explode();
    }
  }

  void explode() {
    isExploding = true;
    removeFromParent();
    print('[OrbitalMine] Exploded!');
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Explode on contact with player
    if (other is PlayerShip) {
      other.takeDamage(25.0);
      explode();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw mine body
    final minePaint = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.x / 2,
      minePaint,
    );

    // Draw spikes
    final spikePaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final spikeLength = size.x / 2 + 4;
      final x = centerX + cos(angle) * spikeLength;
      final y = centerY + sin(angle) * spikeLength;

      canvas.drawCircle(
        Offset(x, y),
        2,
        spikePaint,
      );
    }

    // Draw red warning light
    final lightPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      3,
      lightPaint,
    );
  }
}
