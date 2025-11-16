import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

class LootManager extends Component with HasGameRef<SpaceShooterGame> {
  LootManager({required SpaceShooterGame game});

  @override
  void update(double dt) {
    super.update(dt);
    // Loot is managed by individual loot components
  }
}
