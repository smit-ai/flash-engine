import 'package:flutter/material.dart';
import '../../core/rendering/light.dart';
import '../framework.dart';

class FlashLight extends FlashNodeWidget {
  final Color color;
  final double intensity;

  const FlashLight({
    super.key,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    this.color = Colors.white,
    this.intensity = 1.0,
  });

  @override
  State<FlashLight> createState() => _FlashLightState();
}

class _FlashLightState extends FlashNodeWidgetState<FlashLight, FlashLightNode> {
  @override
  FlashLightNode createNode() => FlashLightNode(color: widget.color, intensity: widget.intensity);

  @override
  void applyProperties([FlashLight? oldWidget]) {
    super.applyProperties(oldWidget);
    node.color = widget.color;
    node.intensity = widget.intensity;
  }
}
