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

    // Create upgrade cards with responsive sizing
    // Increased card dimensions to accommodate more text
    final scaleFactor = (size.x / 800.0).clamp(0.5, 1.5);
    var cardWidth = (280.0 * scaleFactor).clamp(200.0, 400.0);
    var cardHeight = (380.0 * scaleFactor).clamp(280.0, 500.0);
    final spacing = (30.0 * scaleFactor).clamp(15.0, 50.0);

    // Calculate total width and adjust if it exceeds screen width
    var totalWidth =
        (cardWidth * availableUpgrades.length) +
        (spacing * (availableUpgrades.length - 1));

    // If cards don't fit, reduce card size
    if (totalWidth > size.x * 0.95) {
      final availableWidth = size.x * 0.95;
      cardWidth = (availableWidth - (spacing * (availableUpgrades.length - 1))) / availableUpgrades.length;
      cardHeight = cardWidth * 1.25; // Maintain aspect ratio
      totalWidth = availableWidth;

      print('[UpgradeOverlay] Adjusted card size to fit screen: $cardWidth x $cardHeight');
    }

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

    // Responsive sizing based on viewport
    final scaleFactor = (size.x / 800.0).clamp(0.7, 1.5);
    final titleFontSize = (48 * scaleFactor).clamp(32.0, 64.0);
    final subtitleFontSize = (24 * scaleFactor).clamp(16.0, 32.0);

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
      Vector2(size.x / 2, 100 * scaleFactor.clamp(0.8, 1.2)),
      anchor: Anchor.center,
    );

    final subtitleStyle = TextPaint(
      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: subtitleFontSize),
    );

    subtitleStyle.render(
      canvas,
      'Choose an upgrade',
      Vector2(size.x / 2, 160 * scaleFactor.clamp(0.8, 1.2)),
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

    // Responsive sizing based on card size
    final scaleFactor = (size.x / 280.0).clamp(0.7, 1.5);
    final iconFontSize = (64 * scaleFactor).clamp(40.0, 80.0);
    final nameFontSize = (20 * scaleFactor).clamp(14.0, 26.0);
    final descFontSize = (14 * scaleFactor).clamp(11.0, 18.0);
    final statusFontSize = (13 * scaleFactor).clamp(10.0, 16.0);
    final borderWidth = (3 * scaleFactor).clamp(2.0, 5.0);
    final padding = (16 * scaleFactor).clamp(10.0, 24.0);

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

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(12 * scaleFactor.clamp(0.8, 1.2))),
      cardPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(12 * scaleFactor.clamp(0.8, 1.2))),
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
