import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

class TouchJoystick extends PositionComponent
    with HasGameRef<SpaceShooterGame>, DragCallbacks {
  Vector2? touchStartPosition; // World position where touch started
  Vector2? currentTouchOffset;
  final double maxOffset = 80.0; // Maximum drag distance
  bool isDragging = false;

  TouchJoystick() : super(anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Cover entire viewport to capture touches anywhere
    size = gameRef.camera.viewport.size.clone();
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Keep size synced with viewport
    size = gameRef.camera.viewport.size.clone();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Store the world position where touch started
    touchStartPosition = event.localPosition.clone();
    currentTouchOffset = Vector2.zero();
    isDragging = true;
    gameRef.player.handleTouchStart(touchStartPosition!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (touchStartPosition != null && isDragging) {
      // Calculate offset from start position
      var offset = event.localEndPosition - touchStartPosition!;

      // Clamp offset to max radius
      if (offset.length > maxOffset) {
        offset = offset.normalized() * maxOffset;
      }

      currentTouchOffset = offset;
      gameRef.player.handleTouchMove(touchStartPosition! + offset);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    touchStartPosition = null;
    currentTouchOffset = null;
    isDragging = false;
    gameRef.player.handleTouchEnd();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Only render joystick when actively dragging
    if (isDragging && touchStartPosition != null) {
      // Draw outer circle at touch start position
      final outerPaint = Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(touchStartPosition!.toOffset(), maxOffset, outerPaint);

      // Draw inner stick/thumb
      final thumbPosition = touchStartPosition! + (currentTouchOffset ?? Vector2.zero());
      final innerPaint = Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(thumbPosition.toOffset(), 25, innerPaint);

      // Draw center dot
      final centerPaint = Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(touchStartPosition!.toOffset(), 8, centerPaint);
    }
  }
}
