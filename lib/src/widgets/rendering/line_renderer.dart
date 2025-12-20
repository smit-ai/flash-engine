import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../../core/graph/node.dart';
import '../framework.dart';

/// A widget that renders a line based on a list of points.
class FlashLineRenderer extends FlashNodeWidget {
  /// The points that define the line, in local space.
  final List<v.Vector3> points;

  /// The color of the line if [gradient] is not provided.
  final Color color;

  /// The width of the line.
  final double width;

  /// An optional gradient to apply to the line.
  final Gradient? gradient;

  /// Whether to close the line by connecting the last point to the first.
  final bool isLoop;

  /// Whether to apply a glow effect to the line.
  final bool glow;

  /// The blur radius for the glow effect.
  final double glowSigma;

  const FlashLineRenderer({
    super.key,
    required this.points,
    this.color = Colors.white,
    this.width = 2.0,
    this.gradient,
    this.isLoop = false,
    this.glow = false,
    this.glowSigma = 8.0,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'LineRenderer',
  });

  @override
  State<FlashLineRenderer> createState() => _FlashLineRendererState();
}

class _FlashLineRendererState extends FlashNodeWidgetState<FlashLineRenderer, _LineNode> {
  @override
  _LineNode createNode() => _LineNode(
    points: widget.points,
    color: widget.color,
    width: widget.width,
    lineGradient: widget.gradient,
    isLoop: widget.isLoop,
    glow: widget.glow,
    glowSigma: widget.glowSigma,
  )..name = widget.name ?? 'LineRenderer';

  @override
  void applyProperties([FlashLineRenderer? oldWidget]) {
    super.applyProperties(oldWidget);
    node.points = widget.points;
    node.color = widget.color;
    node.width = widget.width;
    node.lineGradient = widget.gradient;
    node.isLoop = widget.isLoop;
    node.glow = widget.glow;
    node.glowSigma = widget.glowSigma;
  }
}

class _LineNode extends FlashNode {
  List<v.Vector3> points;
  Color color;
  double width;
  Gradient? lineGradient;
  bool isLoop;
  bool glow;
  double glowSigma;

  _LineNode({
    required this.points,
    required this.color,
    required this.width,
    required this.lineGradient,
    required this.isLoop,
    required this.glow,
    required this.glowSigma,
  });

  @override
  void draw(Canvas canvas) {
    if (points.length < 2) return;

    final path = Path();
    // In local space, we draw points directly.
    // Flash coordinate system is Y-up, and viewport applies Y-down scale.
    // So we draw with positive Y!
    path.moveTo(points.first.x, points.first.y);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    if (isLoop) {
      path.close();
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (lineGradient != null) {
      Rect bounds = path.getBounds();
      paint.shader = lineGradient!.createShader(bounds);
    } else {
      paint.color = color;
    }

    if (glow) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma);

      if (lineGradient != null) {
        glowPaint.shader = lineGradient!.createShader(path.getBounds());
      } else {
        glowPaint.color = color.withValues(alpha: 0.3);
      }
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, paint);
  }
}
