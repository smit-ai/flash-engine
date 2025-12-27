import 'package:flutter/material.dart';
import '../../core/rendering/camera.dart';
import '../../core/systems/engine.dart';
import '../framework.dart';

class FCamera extends FNodeWidget {
  final double fov;
  final double near;
  final double far;

  const FCamera({
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
  State<FCamera> createState() => _FCameraState();
}

class _FCameraState extends FNodeWidgetState<FCamera, FCameraNode> {
  FEngine? _engine; // Cache engine reference for safe disposal

  @override
  FCameraNode createNode() => FCameraNode()
    ..fov = widget.fov
    ..near = widget.near
    ..far = widget.far;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache engine reference and register camera
    _engine = context.dependOnInheritedWidgetOfExactType<InheritedFNode>()?.engine;
    _engine?.registerCamera(node);
  }

  @override
  void dispose() {
    // Use cached engine reference (safe during disposal)
    _engine?.unregisterCamera(node);
    super.dispose();
  }

  @override
  void applyProperties([FCamera? oldWidget]) {
    super.applyProperties(oldWidget);
    node.fov = widget.fov;
    node.near = widget.near;
    node.far = widget.far;
  }
}
