import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';

class UpgradeOverlay extends PositionComponent
    with HasGameRef<SpaceShooterGame>, TapCallbacks {
  final Function(Upgrade) onUpgradeSelected;
  final List<Upgrade> availableUpgrades;
  final List<UpgradeCard> cards = [];
  bool _hasRendered = false;

  UpgradeOverlay({
    required this.onUpgradeSelected,
    required this.availableUpgrades,
  }) : super(priority: 100);

  @override
  Future<void> onLoad() async {
    print('[UpgradeOverlay] onLoad started');

    await super.onLoad();

    // Get viewport size from camera viewport
    size = gameRef.camera.viewport.size.clone();
    position = Vector2.zero();

    print('[UpgradeOverlay] Size set to: $size');

    // Create upgrade cards
    final cardWidth = 200.0;
    final cardHeight = 250.0;
    final spacing = 30.0;
    final totalWidth =
        (cardWidth * availableUpgrades.length) +
        (spacing * (availableUpgrades.length - 1));
    final startX = (size.x - totalWidth) / 2;

    print('[UpgradeOverlay] Creating ${availableUpgrades.length} cards');

    for (int i = 0; i < availableUpgrades.length; i++) {
      final card = UpgradeCard(
        upgrade: availableUpgrades[i],
        onSelected: () {
          print('[UpgradeOverlay] Card selected: ${availableUpgrades[i].name}');
          onUpgradeSelected(availableUpgrades[i]);
          removeFromParent();
        },
        size: Vector2(cardWidth, cardHeight),
        position: Vector2(
          startX + (i * (cardWidth + spacing)) + cardWidth / 2,
          size.y / 2,
        ),
      );
      cards.add(card);
      add(card);
      print('[UpgradeOverlay] Added card ${i + 1}: ${availableUpgrades[i].name}');
    }

    print('[UpgradeOverlay] onLoad completed successfully');
  }

  @override
  void onMount() {
    super.onMount();
    print('[UpgradeOverlay] onMount called - component is now in the tree');
    print('[UpgradeOverlay] Parent: ${parent?.runtimeType}, isMounted: $isMounted');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Debug: Print render call only once
    if (!_hasRendered) {
      print('[UpgradeOverlay] render() called for the first time - size: $size, position: $position, priority: $priority');
      _hasRendered = true;
    }

    // Dark overlay
    final bgPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // Title
    final titleStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
    );

    titleStyle.render(
      canvas,
      'LEVEL UP!',
      Vector2(size.x / 2, 100),
      anchor: Anchor.center,
    );

    final subtitleStyle = TextPaint(
      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 24),
    );

    subtitleStyle.render(
      canvas,
      'Choose an upgrade',
      Vector2(size.x / 2, 160),
      anchor: Anchor.center,
    );
  }
}

class UpgradeCard extends PositionComponent with TapCallbacks {
  final Upgrade upgrade;
  final VoidCallback onSelected;
  bool isHovered = false;
  bool _hasRendered = false;

  UpgradeCard({
    required this.upgrade,
    required this.onSelected,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center);

  @override
  void onTapDown(TapDownEvent event) {
    print('[UpgradeCard] Tapped: ${upgrade.name}');
    onSelected();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Debug: Print render call only once per card
    if (!_hasRendered) {
      print('[UpgradeCard] render() called for ${upgrade.name} - size: $size, position: $position');
      _hasRendered = true;
    }

    // Card background
    final cardPaint = Paint()
      ..color = isHovered ? const Color(0xFF333333) : const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      cardPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      borderPaint,
    );

    // Icon
    final iconStyle = TextPaint(style: TextStyle(fontSize: 64));

    iconStyle.render(
      canvas,
      upgrade.icon,
      Vector2(0, -60),
      anchor: Anchor.center,
    );

    // Name
    final nameStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );

    nameStyle.render(
      canvas,
      upgrade.name,
      Vector2(0, 10),
      anchor: Anchor.center,
    );

    // Description
    final descStyle = TextPaint(
      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
    );

    descStyle.render(
      canvas,
      upgrade.description,
      Vector2(0, 50),
      anchor: Anchor.center,
    );
  }
}
