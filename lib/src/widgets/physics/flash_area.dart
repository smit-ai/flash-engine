import 'package:flutter/material.dart';
import '../../core/systems/physics.dart';
import '../framework.dart';

/// An area that detects collisions with other bodies.
/// Currently simplified to circular areas in the native core.
class FArea extends FNodeWidget {
  final int shapeType;
  final double width;
  final double height;
  final void Function(FPhysicsBody)? onCollisionStart;
  final void Function(FPhysicsBody)? onCollisionEnd;

  const FArea({
    super.key,
    this.shapeType = FPhysics.circle,
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
  State<FArea> createState() => _FAreaState();
}

class _FAreaState extends FNodeWidgetState<FArea, FPhysicsBody> {
  @override
  FPhysicsBody createNode() {
    final element = context.getElementForInheritedWidgetOfExactType<InheritedFNode>();
    final engine = (element?.widget as InheritedFNode?)?.engine;
    final world = engine?.physicsWorld;

    if (world == null && engine != null) {
      engine.physicsWorld = FPhysicsSystem(gravity: FPhysics.standardGravity);
    }

    final activeWorld = engine?.physicsWorld;
    if (activeWorld == null) {
      throw Exception('FArea: Failed to initialize physics world');
    }

    final node = FPhysicsBody(
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
