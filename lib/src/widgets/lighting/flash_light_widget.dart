import 'package:flutter/material.dart';
import '../../core/rendering/light.dart';
import '../framework.dart';

class FLight extends FNodeWidget {
  final Color color;
  final double intensity;

  const FLight({
    super.key,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    this.color = Colors.white,
    this.intensity = 1.0,
  });

  @override
  State<FLight> createState() => _FLightState();
}

class _FLightState extends FNodeWidgetState<FLight, FLightNode> {
  @override
  FLightNode createNode() => FLightNode(color: widget.color, intensity: widget.intensity);

  @override
  void applyProperties([FLight? oldWidget]) {
    super.applyProperties(oldWidget);
    node.color = widget.color;
    node.intensity = widget.intensity;
  }
}
