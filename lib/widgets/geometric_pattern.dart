import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Subtle Islamic 8-point star (khatam) lattice used as a whisper-quiet
/// backdrop for the chat viewport. Rendered once inside a RepaintBoundary so
/// it never repaints while messages stream.
class GeometricPattern extends StatelessWidget {
  final double opacity;

  const GeometricPattern({super.key, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _KhatamLatticePainter(opacity: opacity),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _KhatamLatticePainter extends CustomPainter {
  final double opacity;

  _KhatamLatticePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const cell = 72.0;
    final rows = (size.height / cell).ceil() + 1;
    final cols = (size.width / cell).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * cell + (r.isOdd ? cell / 2 : 0);
        final cy = r * cell;
        _drawKhatam(canvas, Offset(cx, cy), cell * 0.32, paint);
      }
    }
  }

  void _drawKhatam(Canvas canvas, Offset center, double half, Paint paint) {
    // Two overlapping squares: upright + 45° rotated (Rub el Hizb).
    final upright = Rect.fromCenter(center: center, width: half * 2, height: half * 2);
    canvas.drawRect(upright, paint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(upright, paint);
    canvas.restore();

    // Center dot.
    canvas.drawCircle(center, 1.6, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant _KhatamLatticePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
