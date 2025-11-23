import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

class TouchJoystick extends PositionComponent
    with HasGameRef<SpaceShooterGame>, DragCallbacks {
  Vector2? touchStartPosition;
  Vector2? currentTouchOffset;
  final double maxOffset = 50.0;

  TouchJoystick() : super(size: Vector2.all(150), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Position in the center horizontally, below the player
    final viewportSize = gameRef.camera.viewport.size;
    position = Vector2(
      viewportSize.x / 2, // Center horizontally
      viewportSize.y - 150, // Bottom of screen with padding
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    touchStartPosition = event.localPosition;
    currentTouchOffset = Vector2.zero();
    gameRef.player.handleTouchStart(position);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (touchStartPosition != null) {
      var offset = event.localEndPosition - touchStartPosition!;

      // Clamp offset
      if (offset.length > maxOffset) {
        offset = offset.normalized() * maxOffset;
      }

      currentTouchOffset = offset;
      gameRef.player.handleTouchMove(position + offset);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    touchStartPosition = null;
    currentTouchOffset = null;
    gameRef.player.handleTouchEnd();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw outer circle
    final outerPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, maxOffset, outerPaint);

    // Draw inner stick
    if (currentTouchOffset != null) {
      final innerPaint = Paint()
        ..color = const Color(0xAAFFFFFF)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(currentTouchOffset!.toOffset(), 20, innerPaint);
    } else {
      final innerPaint = Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset.zero, 20, innerPaint);
    }
  }
}
