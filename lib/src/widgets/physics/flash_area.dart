import 'package:flutter/material.dart';
import '../../core/systems/physics.dart';
import '../framework.dart';

/// An area that detects collisions with other bodies.
/// Currently simplified to circular areas in the native core.
class FlashArea extends FlashNodeWidget {
  final int shapeType;
  final double width;
  final double height;
  final void Function(FlashPhysicsBody)? onCollisionStart;
  final void Function(FlashPhysicsBody)? onCollisionEnd;

  const FlashArea({
    super.key,
    this.shapeType = FlashPhysics.circle,
    this.width = 100,
    this.height = 100,
    this.onCollisionStart,
    this.onCollisionEnd,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'Area',
    super.child,
  });

  @override
  State<FlashArea> createState() => _FlashAreaState();
}

class _FlashAreaState extends FlashNodeWidgetState<FlashArea, FlashPhysicsBody> {
  @override
  FlashPhysicsBody createNode() {
    final element = context.getElementForInheritedWidgetOfExactType<InheritedFlashNode>();
    final engine = (element?.widget as InheritedFlashNode?)?.engine;
    final world = engine?.physicsWorld;

    if (world == null && engine != null) {
      engine.physicsWorld = FlashPhysicsSystem(gravity: FlashPhysics.standardGravity);
    }

    final activeWorld = engine?.physicsWorld;
    if (activeWorld == null) {
      throw Exception('FlashArea: Failed to initialize physics world');
    }

    final node = FlashPhysicsBody(
      world: activeWorld.world,
      type: 0, // STATIC/SENSOR
      shapeType: widget.shapeType,
      x: widget.position?.x ?? 0,
      y: widget.position?.y ?? 0,
      width: widget.width,
      height: widget.height,
      rotation: widget.rotation?.z ?? 0,
      name: widget.name ?? 'Area',
    );

    // TODO: Implement native collision callbacks for sensors
    return node;
  }
}
