import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Islamic 8-Pointed Star (Rub el Hizb) with Mihrab/Qalam Motif
/// Faithful vector reproduction of Stitch `shirazi_scholarly_emblem/code.html`
class ShiraziEmblem extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const ShiraziEmblem({super.key, this.size = 36.0, this.strokeWidth = 2.5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmblemPainter(strokeWidth: strokeWidth),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  final double strokeWidth;

  _EmblemPainter({this.strokeWidth = 2.5});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100.0;

    final goldGradient = const LinearGradient(
      colors: [Color(0xFFF3E5AB), Color(0xFFD4AF37), Color(0xFFAA7C11)],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..shader = goldGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;

    final fillPaint = Paint()
      ..color = const Color(0xFF0A1612)
      ..style = PaintingStyle.fill;

    final rectSize = 60.0 * scale;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: rectSize, height: rectSize),
      Radius.circular(8.0 * scale),
    );

    // 1. Rotated Square (45 degrees)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);
    canvas.restore();

    // 2. Upright Square
    final fillPaint2 = Paint()
      ..color = const Color(0xFF0A1612).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint2);
    canvas.drawRRect(rrect, strokePaint);

    // 3. Inner Circle
    final circleStroke = Paint()
      ..shader = goldGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    final circleFill = Paint()
      ..color = const Color(0xFF0D241C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 18.0 * scale, circleFill);
    canvas.drawCircle(center, 18.0 * scale, circleStroke);

    // 4. Central Qalam / Mihrab Tip
    final qalamPaint = Paint()
      ..shader = goldGradient
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(50 * scale, 36 * scale);
    path.cubicTo(45 * scale, 42 * scale, 43 * scale, 47 * scale, 43 * scale, 53 * scale);
    path.cubicTo(43 * scale, 57 * scale, 46 * scale, 61 * scale, 50 * scale, 63 * scale);
    path.cubicTo(54 * scale, 61 * scale, 57 * scale, 57 * scale, 57 * scale, 53 * scale);
    path.cubicTo(57 * scale, 47 * scale, 55 * scale, 42 * scale, 50 * scale, 36 * scale);
    path.close();
    canvas.drawPath(path, qalamPaint);

    // 5. Center dot
    final dotPaint = Paint()
      ..color = const Color(0xFF0A1612)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(50 * scale, 51 * scale), 2.5 * scale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
