import 'package:flutter/material.dart';
import '../../core/rendering/camera.dart';
import '../../core/systems/engine.dart';
import '../framework.dart';

class FlashCamera extends FlashNodeWidget {
  final double fov;
  final double near;
  final double far;

  const FlashCamera({
    super.key,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    super.child,
    this.fov = 60.0,
    this.near = 0.1,
    this.far = 2000.0,
  });

  @override
  State<FlashCamera> createState() => _FlashCameraState();
}

class _FlashCameraState extends FlashNodeWidgetState<FlashCamera, FlashCameraNode> {
  FlashEngine? _engine; // Cache engine reference for safe disposal

  @override
  FlashCameraNode createNode() => FlashCameraNode()
    ..fov = widget.fov
    ..near = widget.near
    ..far = widget.far;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache engine reference and register camera
    _engine = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>()?.engine;
    _engine?.registerCamera(node);
  }

  @override
  void dispose() {
    // Use cached engine reference (safe during disposal)
    _engine?.unregisterCamera(node);
    super.dispose();
  }

  @override
  void applyProperties([FlashCamera? oldWidget]) {
    super.applyProperties(oldWidget);
    node.fov = widget.fov;
    node.near = widget.near;
    node.far = widget.far;
  }
}
