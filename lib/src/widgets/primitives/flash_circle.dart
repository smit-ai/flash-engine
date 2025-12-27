import 'package:flutter/material.dart';
import '../../core/graph/node.dart';
import '../framework.dart';

class FCircle extends FNodeWidget {
  final double radius;
  final Color color;

  const FCircle({
    super.key,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    super.child,
    this.radius = 50,
    this.color = Colors.white,
    super.billboard,
  });

  @override
  State<FCircle> createState() => _FCircleState();
}

class _FCircleState extends FNodeWidgetState<FCircle, _CircleNode> {
  @override
  _CircleNode createNode() => _CircleNode(radius: widget.radius, color: widget.color);

  @override
  void applyProperties([FCircle? oldWidget]) {
    super.applyProperties(oldWidget);
    node.color = widget.color;
    node.radius = widget.radius;
  }
}

class _CircleNode extends FNode {
  double radius;
  Color color;

  _CircleNode({required this.radius, required this.color});

  @override
  void draw(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
  }
}
