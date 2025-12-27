import 'package:flutter/material.dart';
import '../../core/graph/node.dart';
import '../framework.dart';

class FTriangle extends FNodeWidget {
  final double size;
  final Color color;

  const FTriangle({
    super.key,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    super.child,
    this.size = 100,
    this.color = Colors.white,
  });

  @override
  State<FTriangle> createState() => _FTriangleState();
}

class _FTriangleState extends FNodeWidgetState<FTriangle, _TriangleNode> {
  @override
  _TriangleNode createNode() => _TriangleNode(size: widget.size, color: widget.color);

  @override
  void applyProperties([FTriangle? oldWidget]) {
    super.applyProperties(oldWidget);
    node.color = widget.color;
    node.size = widget.size;
  }
}

class _TriangleNode extends FNode {
  double size;
  Color color;

  _TriangleNode({required this.size, required this.color});

  @override
  void draw(Canvas canvas) {
    final path = Path();
    final half = size / 2;
    path.moveTo(0, -half);
    path.lineTo(half, half);
    path.lineTo(-half, half);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
