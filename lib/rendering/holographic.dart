import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Shared sci-fi HOLOGRAPHIC rendering system.
///
/// Every enemy/boss routes its shape through this so the whole roster reads as
/// one cohesive look: a translucent holo-fill, faint scanlines, a soft glow halo
/// and a bright wireframe outline. Keeping the drawing here (instead of each
/// component hand-rolling Paints) is the single source of truth for the style -
/// retuning the palette or glow updates every enemy at once.
class Holo {
  Holo._();

  // Palette (teal / blue / purple on deep navy)
  static const Color teal = Color(0xFF38F9D7);
  static const Color blue = Color(0xFF43A0FF);
  static const Color purple = Color(0xFFB16CFF);
  static const Color bg = Color(0xFF05101A);
  static const Color white = Color(0xFFEAFBFF);
  static const Color danger = Color(0xFFFF5C7A); // telegraph / enraged accents

  /// Build a regular-polygon [Path] centred in a [size] box (top-left origin).
  /// [rotation] of -pi/2 puts the first vertex at the top (matches the existing
  /// enemy shapes).
  static Path polygonPath(Vector2 size, int sides, {double rotation = -pi / 2}) {
    final path = Path();
    final cx = size.x / 2;
    final cy = size.y / 2;
    final rx = size.x / 2;
    final ry = size.y / 2;
    for (int i = 0; i < sides; i++) {
      final a = (i * 2 * pi / sides) + rotation;
      final x = cx + cos(a) * rx;
      final y = cy + sin(a) * ry;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Draw a holographic shape: glow halo + translucent fill + faint scanlines +
  /// bright wireframe outline.
  ///
  /// [hit] (0..1) flashes the shape toward white for damage feedback - pass a
  /// decaying value from the component.
  static void drawShape(
    Canvas canvas,
    Path path, {
    Color color = teal,
    double strokeWidth = 1.6,
    double glow = 6.0,
    double fillOpacity = 0.16,
    bool scanlines = true,
    double hit = 0.0,
    Rect? bounds,
  }) {
    final lineColor = Color.lerp(color, white, hit.clamp(0.0, 1.0)) ?? color;
    final b = bounds ?? path.getBounds();

    // Translucent holo fill
    if (fillOpacity > 0) {
      final fill = Paint()
        ..color = color.withValues(alpha: fillOpacity + 0.25 * hit)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
    }

    // Scanlines clipped to the shape
    if (scanlines && b.height > 4) {
      canvas.save();
      canvas.clipPath(path);
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.16)
        ..strokeWidth = 1.0;
      const spacing = 4.0;
      for (double y = b.top; y <= b.bottom; y += spacing) {
        canvas.drawLine(Offset(b.left, y), Offset(b.right, y), linePaint);
      }
      canvas.restore();
    }

    // Soft glow halo (blurred stroke)
    if (glow > 0) {
      final glowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow);
      canvas.drawPath(path, glowPaint);
    }

    // Bright wireframe
    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, stroke);
  }

  /// Holographic circle (uses [drawShape] with a circle path).
  static void drawCircle(
    Canvas canvas,
    Offset center,
    double radius, {
    Color color = teal,
    double strokeWidth = 1.6,
    double glow = 6.0,
    double fillOpacity = 0.16,
    double hit = 0.0,
  }) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    drawShape(canvas, path,
        color: color,
        strokeWidth: strokeWidth,
        glow: glow,
        fillOpacity: fillOpacity,
        hit: hit);
  }

  /// Targeting brackets that frame a boss - four rotating corner arcs.
  static void reticle(
    Canvas canvas,
    Offset center,
    double radius, {
    Color color = purple,
    double rotation = 0.0,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const arc = 0.32; // radians per bracket
    for (int q = 0; q < 4; q++) {
      final base = rotation + q * pi / 2 - arc / 2;
      canvas.drawArc(rect, base, arc, false, paint);
    }
  }
}
