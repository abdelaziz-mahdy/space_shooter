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
  }) : super(priority: 100, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    print('[UpgradeOverlay] onLoad started');

    await super.onLoad();

    // Get viewport size from camera viewport
    size = gameRef.camera.viewport.size.clone();
    position = Vector2.zero();

    print('[UpgradeOverlay] Size set to: $size');

    // Responsive sizing: cards take up percentage of screen width
    final availableWidth = size.x * 0.9; // Use 90% of screen width
    final spacing = size.x * 0.02; // 2% of screen width for spacing

    // Calculate card width based on number of cards
    final totalSpacing = spacing * (availableUpgrades.length - 1);
    final cardWidth = (availableWidth - totalSpacing) / availableUpgrades.length;
    final cardHeight = cardWidth * 1.4; // Maintain 1:1.4 aspect ratio

    final totalWidth = (cardWidth * availableUpgrades.length) + totalSpacing;

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

  void _repositionCards() {
    if (cards.isEmpty) return;

    final cardWidth = cards.first.size.x;
    final cardHeight = cards.first.size.y;
    final spacing = 30.0;
    final totalWidth =
        (cardWidth * cards.length) + (spacing * (cards.length - 1));
    final startX = (size.x - totalWidth) / 2;

    for (int i = 0; i < cards.length; i++) {
      cards[i].position = Vector2(
        startX + (i * (cardWidth + spacing)) + cardWidth / 2,
        size.y / 2,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Continuously sync size with viewport and reposition cards
    size = gameRef.camera.viewport.size.clone();
    _repositionCards();
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

    // Responsive sizing based on viewport width (percentage-based)
    final titleFontSize = size.x * 0.06; // 6% of viewport width
    final subtitleFontSize = size.x * 0.03; // 3% of viewport width
    final titleY = size.y * 0.12; // 12% from top
    final subtitleY = size.y * 0.18; // 18% from top

    // Title
    final titleStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: titleFontSize,
        fontWeight: FontWeight.bold,
      ),
    );

    titleStyle.render(
      canvas,
      'LEVEL UP!',
      Vector2(size.x / 2, titleY),
      anchor: Anchor.center,
    );

    final subtitleStyle = TextPaint(
      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: subtitleFontSize),
    );

    subtitleStyle.render(
      canvas,
      'Choose an upgrade',
      Vector2(size.x / 2, subtitleY),
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

    // Responsive sizing based on card width (percentage-based)
    final iconFontSize = size.x * 0.22; // 22% of card width
    final nameFontSize = size.x * 0.07; // 7% of card width
    final descFontSize = size.x * 0.05; // 5% of card width
    final statusFontSize = size.x * 0.045; // 4.5% of card width
    final borderWidth = size.x * 0.01; // 1% of card width
    final padding = size.x * 0.06; // 6% of card width

    // Card background
    final cardPaint = Paint()
      ..color = isHovered ? const Color(0xFF333333) : const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw from top-left (0,0) - anchor will handle centering
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final borderRadius = size.x * 0.04; // 4% of card width

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      cardPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      borderPaint,
    );

    // Icon - centered horizontally, upper portion of card
    final iconStyle = TextPaint(style: TextStyle(fontSize: iconFontSize));

    iconStyle.render(
      canvas,
      upgrade.icon,
      Vector2(size.x / 2, padding + iconFontSize / 2),
      anchor: Anchor.center,
    );

    // Name - centered horizontally, below icon
    final nameStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: nameFontSize,
        fontWeight: FontWeight.bold,
      ),
    );

    final nameY = padding + iconFontSize + padding / 2;
    nameStyle.render(
      canvas,
      upgrade.name,
      Vector2(size.x / 2, nameY),
      anchor: Anchor.center,
    );

    // Description - centered horizontally, below name
    final descStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: descFontSize,
        fontStyle: FontStyle.italic,
      ),
    );

    final descY = nameY + nameFontSize + padding / 3;
    descStyle.render(
      canvas,
      upgrade.description,
      Vector2(size.x / 2, descY),
      anchor: Anchor.center,
    );

    // Divider line
    final dividerY = descY + descFontSize + padding / 2;
    final dividerPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(padding, dividerY),
      Offset(size.x - padding, dividerY),
      dividerPaint,
    );

    // Status changes - left-aligned bullet points
    final statusStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFF00FF88),
        fontSize: statusFontSize,
        fontWeight: FontWeight.w500,
      ),
    );

    final statusChanges = upgrade.getStatusChanges();
    var currentY = dividerY + padding / 2;

    for (final change in statusChanges) {
      // Draw bullet point
      final bulletStyle = TextPaint(
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: statusFontSize,
          fontWeight: FontWeight.bold,
        ),
      );

      bulletStyle.render(
        canvas,
        '•',
        Vector2(padding + 5, currentY),
        anchor: Anchor.centerLeft,
      );

      // Draw status text
      statusStyle.render(
        canvas,
        change,
        Vector2(padding + 20, currentY),
        anchor: Anchor.centerLeft,
      );

      currentY += statusFontSize + 6;
    }
  }
}
