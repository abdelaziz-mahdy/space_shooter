import 'package:flame/components.dart';
import '../components/enemies/base_enemy.dart';
import '../game/space_shooter_game.dart';

/// Centralized targeting system for finding and filtering enemies
/// All weapon targeting and homing behavior should use this class
class TargetingSystem {
  /// Find the nearest targetable enemy within range
  /// Returns null if no valid target is found
  static BaseEnemy? findNearestEnemy({
    required SpaceShooterGame game,
    required Vector2 fromPosition,
    double maxRange = double.infinity,
    bool onlyTargetable = true,
  }) {
    BaseEnemy? nearest;
    double nearestDistance = maxRange;

    final allEnemies = game.activeEnemies;

    for (final enemy in allEnemies) {
      // Skip non-targetable enemies if requested
      if (onlyTargetable && !enemy.isTargetable) continue;

      final distance = fromPosition.distanceTo(enemy.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = enemy;
      }
    }

    return nearest;
  }

  /// Find multiple nearest enemies within range
  /// Returns a list sorted by distance (nearest first)
  ///
  /// Parameters:
  /// - maxCount: Maximum number of enemies to return (null = unlimited)
  /// - excludeEnemy: Enemy to exclude from results (e.g., already hit enemy)
  static List<BaseEnemy> findNearestEnemies({
    required SpaceShooterGame game,
    required Vector2 fromPosition,
    double? maxDistance,
    int? maxCount,
    BaseEnemy? excludeEnemy,
    bool onlyTargetable = true,
  }) {
    // Optimized path for finding single nearest enemy (most common case)
    if (maxCount == 1) {
      final nearest = findNearestEnemy(
        game: game,
        fromPosition: fromPosition,
        maxRange: maxDistance ?? double.infinity,
        onlyTargetable: onlyTargetable,
      );

      if (nearest != null && nearest != excludeEnemy) {
        return [nearest];
      }
      return [];
    }

    // General path for multiple enemies
    final allEnemies = game.activeEnemies;
    final filteredEnemies = <BaseEnemy>[];

    for (final enemy in allEnemies) {
      // Skip excluded enemy
      if (enemy == excludeEnemy) continue;

      // Skip non-targetable enemies if requested
      if (onlyTargetable && !enemy.isTargetable) continue;

      // Check distance if specified
      if (maxDistance != null) {
        final distance = fromPosition.distanceTo(enemy.position);
        if (distance > maxDistance) continue;
      }

      filteredEnemies.add(enemy);
    }

    // Sort by distance (nearest first)
    filteredEnemies.sort((a, b) {
      final distA = fromPosition.distanceTo(a.position);
      final distB = fromPosition.distanceTo(b.position);
      return distA.compareTo(distB);
    });

    // Limit count if specified
    if (maxCount != null && filteredEnemies.length > maxCount) {
      return filteredEnemies.sublist(0, maxCount);
    }

    return filteredEnemies;
  }

  /// Find all enemies within a circular area
  static List<BaseEnemy> findEnemiesInRadius({
    required SpaceShooterGame game,
    required Vector2 center,
    required double radius,
    BaseEnemy? excludeEnemy,
    bool onlyTargetable = true,
  }) {
    return findNearestEnemies(
      game: game,
      fromPosition: center,
      maxDistance: radius,
      excludeEnemy: excludeEnemy,
      onlyTargetable: onlyTargetable,
    );
  }

  /// Find all enemies within a cone (for beam weapons)
  ///
  /// Parameters:
  /// - origin: Starting point of the cone
  /// - direction: Direction the cone is pointing (normalized)
  /// - maxRange: Maximum distance from origin
  /// - coneAngle: Half-angle of the cone in radians (e.g., 0.174 = ~10 degrees)
  static List<BaseEnemy> findEnemiesInCone({
    required SpaceShooterGame game,
    required Vector2 origin,
    required Vector2 direction,
    required double maxRange,
    required double coneAngle,
    bool onlyTargetable = true,
  }) {
    final allEnemies = game.activeEnemies;
    final enemiesInCone = <BaseEnemy>[];
    final directionNormalized = direction.normalized();

    for (final enemy in allEnemies) {
      // Skip non-targetable enemies if requested
      if (onlyTargetable && !enemy.isTargetable) continue;

      final toEnemy = enemy.position - origin;
      final distance = toEnemy.length;

      // Skip enemies beyond range
      if (distance > maxRange) continue;

      // Calculate angle between direction and enemy
      final toEnemyNormalized = toEnemy.normalized();
      final dotProduct = directionNormalized.dot(toEnemyNormalized);
      final angleToEnemy = dotProduct; // cos(angle)

      // Check if enemy is within cone angle
      // cos(coneAngle) gives us the threshold for the dot product
      if (angleToEnemy >= (1.0 - coneAngle * 2)) {
        enemiesInCone.add(enemy);
      }
    }

    // Sort by distance (nearest first)
    enemiesInCone.sort((a, b) {
      final distA = origin.distanceTo(a.position);
      final distB = origin.distanceTo(b.position);
      return distA.compareTo(distB);
    });

    return enemiesInCone;
  }

  /// Check if a specific position is within a beam's path
  /// Used by railgun and laser beam weapons
  ///
  /// Returns true if the target position is close enough to the beam line
  static bool isPositionInBeamPath({
    required Vector2 beamStart,
    required Vector2 beamDirection,
    required double beamMaxRange,
    required Vector2 targetPosition,
    required double beamRadius,
  }) {
    final directionNormalized = beamDirection.normalized();

    // Vector from beam start to target
    final toTarget = targetPosition - beamStart;

    // Project target position onto beam direction
    final projectionLength = toTarget.dot(directionNormalized);

    // Check if target is within beam range
    if (projectionLength < 0 || projectionLength > beamMaxRange) {
      return false;
    }

    // Calculate closest point on beam to target
    final closestPoint = beamStart + (directionNormalized * projectionLength);

    // Calculate distance from target to beam line
    final distanceToBeam = targetPosition.distanceTo(closestPoint);

    // Check if target is close enough to beam
    return distanceToBeam <= beamRadius;
  }

  /// Find all enemies in a beam's path (for railgun, laser beam)
  static List<BaseEnemy> findEnemiesInBeam({
    required SpaceShooterGame game,
    required Vector2 beamStart,
    required Vector2 beamDirection,
    required double beamMaxRange,
    required double beamRadius,
    bool onlyTargetable = true,
  }) {
    final allEnemies = game.activeEnemies;
    final enemiesInBeam = <BaseEnemy>[];
    final directionNormalized = beamDirection.normalized();

    for (final enemy in allEnemies) {
      // Skip non-targetable enemies if requested
      if (onlyTargetable && !enemy.isTargetable) continue;

      // Approximate enemy radius
      final enemyRadius = enemy.size.length / 2;

      if (isPositionInBeamPath(
        beamStart: beamStart,
        beamDirection: directionNormalized,
        beamMaxRange: beamMaxRange,
        targetPosition: enemy.position,
        beamRadius: beamRadius + enemyRadius,
      )) {
        enemiesInBeam.add(enemy);
      }
    }

    return enemiesInBeam;
  }
}
