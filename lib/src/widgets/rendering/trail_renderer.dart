import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../../core/graph/node.dart';
import '../../core/rendering/light.dart';
import '../framework.dart';

/// A widget that renders a trailing line behind its parent node.
class FlashTrailRenderer extends StatefulWidget {
  /// How long points stay in the trail (seconds).
  final double lifetime;

  /// Minimum distance between points to record a new vertex.
  final double minVertexDistance;

  /// Starting color of the trail.
  final Color startColor;

  /// Ending color of the trail.
  final Color endColor;

  /// Starting width of the trail.
  final double startWidth;

  /// Ending width of the trail.
  final double endWidth;

  /// Optional gradient. If provided, overrides colors.
  final Gradient? gradient;

  const FlashTrailRenderer({
    super.key,
    this.lifetime = 1.0,
    this.minVertexDistance = 5.0,
    this.startColor = Colors.white,
    this.endColor = Colors.transparent,
    this.startWidth = 10.0,
    this.endWidth = 1.0,
    this.gradient,
  });

  @override
  State<FlashTrailRenderer> createState() => _FlashTrailRendererState();
}

class _FlashTrailRendererState extends State<FlashTrailRenderer> {
  late _TrailNode _node;
  FlashNode? _parent;

  @override
  void initState() {
    super.initState();
    _node = _TrailNode(
      lifetime: widget.lifetime,
      minVertexDistance: widget.minVertexDistance,
      startColor: widget.startColor,
      endColor: widget.endColor,
      startWidth: widget.startWidth,
      endWidth: widget.endWidth,
      trailGradient: widget.gradient,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inherited = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
    final newParent = inherited?.node;
    if (_parent != newParent) {
      _parent?.removeChild(_node);
      _parent = newParent;
      _parent?.addChild(_node);
    }
  }

  @override
  void didUpdateWidget(FlashTrailRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _node.lifetime = widget.lifetime;
    _node.minVertexDistance = widget.minVertexDistance;
    _node.startColor = widget.startColor;
    _node.endColor = widget.endColor;
    _node.startWidth = widget.startWidth;
    _node.endWidth = widget.endWidth;
    _node.trailGradient = widget.gradient;
  }

  @override
  void dispose() {
    _parent?.removeChild(_node);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _TrailPoint {
  final v.Vector3 position;
  final double time;
  _TrailPoint({required this.position, required this.time});
}

class _TrailNode extends FlashNode {
  double lifetime;
  double minVertexDistance;
  Color startColor;
  Color endColor;
  double startWidth;
  double endWidth;
  Gradient? trailGradient;

  final List<_TrailPoint> _points = [];
  double _elapsed = 0;

  _TrailNode({
    required this.lifetime,
    required this.minVertexDistance,
    required this.startColor,
    required this.endColor,
    required this.startWidth,
    required this.endWidth,
    required this.trailGradient,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (parent == null) return;

    final currentWorldPos = parent!.worldPosition;

    // Remove old points
    _points.removeWhere((p) => _elapsed - p.time > lifetime);

    // Add new point if distance threshold met
    if (_points.isEmpty || (currentWorldPos - _points.last.position).length > minVertexDistance) {
      _points.add(_TrailPoint(position: currentWorldPos.clone(), time: _elapsed));
    }
  }

  @override
  void renderSelf(Canvas canvas, Matrix4 viewportProjectionMatrix, List<FlashLight> activeLights) {
    if (!visible || _points.length < 2) return;

    // Trail points are in WORLD SPACE.
    // So we apply ONLY the viewportProjectionMatrix, NOT the worldMatrix of this node.
    canvas.save();
    canvas.transform(viewportProjectionMatrix.storage);
    draw(canvas);
    canvas.restore();
  }

  @override
  void draw(Canvas canvas) {
    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];

      final age1 = (_elapsed - p1.time).clamp(0.0, lifetime);
      final t1 = 1.0 - (age1 / lifetime);

      final age2 = (_elapsed - p2.time).clamp(0.0, lifetime);
      final t2 = 1.0 - (age2 / lifetime);

      final width1 = endWidth + (startWidth - endWidth) * t1;
      final width2 = endWidth + (startWidth - endWidth) * t2;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (width1 + width2) / 2
        ..style = PaintingStyle.stroke;

      paint.color = Color.lerp(endColor, startColor, (t1 + t2) / 2)!;

      canvas.drawLine(Offset(p1.position.x, p1.position.y), Offset(p2.position.x, p2.position.y), paint);
    }
  }
}
