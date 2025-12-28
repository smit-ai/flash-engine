import 'dart:math' as math;
import 'package:flutter/material.dart';

class DiamondWidget extends StatefulWidget {
  const DiamondWidget({super.key});

  @override
  State<DiamondWidget> createState() => _DiamondWidgetState();
}

class _DiamondWidgetState extends State<DiamondWidget> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          painter: GemPainter(progress: _anim.value),
          size: const Size(40, 40),
        );
      },
    );
  }
}

class GemPainter extends CustomPainter {
  final double progress;

  GemPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // 1. DRAW SHADOW (On the grid plane)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 7), shadowPaint);

    // 2. DRAW GEM (Sitting on the floor)
    const double dSize = 12.0;
    final double rotateAngle = progress * math.pi * 2;
    // Offset by its half-height (1.1 * dSize) so the bottom tip is at 0
    final double floorHeight = -dSize * 1.1;

    canvas.save();
    canvas.translate(cx, cy + floorHeight);

    // Draw Gem faces
    _drawGem(canvas, rotateAngle);

    canvas.restore();
  }

  void _drawGem(Canvas canvas, double angle) {
    const double dSize = 12.0;

    // Points for hex bipyramid (gem shape)
    // Top point
    final Offset top = const Offset(0, -dSize * 1.1);
    // Bottom point
    final Offset bottom = const Offset(0, dSize * 1.1);

    // Mid-plane points (6 points for a hexagonal look)
    final List<Offset> midPoints = [];
    for (int i = 0; i < 6; i++) {
      final double a = angle + (i * math.pi * 2 / 6);
      midPoints.add(Offset(math.cos(a) * dSize, math.sin(a) * dSize * 0.5)); // 0.5 for isometric squish
    }

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.3);

    // Draw faces (alternating colors for "facet" effect)
    for (int i = 0; i < 6; i++) {
      final p1 = midPoints[i];
      final p2 = midPoints[(i + 1) % 6];

      // Top faces
      final pathTop = Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      fillPaint.color = HSLColor.fromAHSL(1.0, 190, 0.8, 0.4 + (i % 3) * 0.1).toColor();
      canvas.drawPath(pathTop, fillPaint);
      canvas.drawPath(pathTop, linePaint);

      // Bottom faces
      final pathBottom = Path()
        ..moveTo(bottom.dx, bottom.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      fillPaint.color = HSLColor.fromAHSL(1.0, 190, 0.8, 0.3 + (i % 3) * 0.1).toColor();
      canvas.drawPath(pathBottom, fillPaint);
      canvas.drawPath(pathBottom, linePaint);
    }

    // Add a shiny highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-dSize * 0.3, -dSize * 0.5), dSize * 0.2, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant GemPainter oldDelegate) => oldDelegate.progress != progress;
}
