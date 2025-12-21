import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../../core/systems/physics.dart';
import '../framework.dart';

/// Declarative widget to initialize a physics world in the Flash engine.
class FlashPhysicsWorld extends StatefulWidget {
  final v.Vector2? gravity;

  const FlashPhysicsWorld({super.key, this.gravity});

  @override
  State<FlashPhysicsWorld> createState() => _FlashPhysicsWorldState();
}

class _FlashPhysicsWorldState extends State<FlashPhysicsWorld> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final element = context.getElementForInheritedWidgetOfExactType<InheritedFlashNode>();
    final engine = (element?.widget as InheritedFlashNode?)?.engine;

    if (engine != null && engine.physicsWorld == null) {
      engine.physicsWorld = FlashPhysicsSystem(gravity: widget.gravity);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A rigid body that reacts to physics forces. Native implementation.
class FlashRigidBody extends FlashNodeWidget {
  final int type; // 0: Static, 1: Kinematic, 2: Dynamic
  final int shapeType; // FlashPhysics.circle or FlashPhysics.box
  final double width;
  final double height;
  final v.Vector2? initialVelocity;
  final void Function(FlashPhysicsBody)? onCollision;
  final void Function(FlashPhysicsBody)? onUpdate;

  const FlashRigidBody({
    super.key,
    this.type = 2, // Default: Dynamic
    this.shapeType = FlashPhysics.box, // Default to box for convenience
    this.width = 50,
    this.height = 50,
    this.initialVelocity,
    this.onCollision,
    this.onUpdate,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'RigidBody',
    super.child,
  });

  /// Shorthand constructor for squares/circles
  FlashRigidBody.square({
    super.key,
    this.type = 2,
    this.shapeType = FlashPhysics.box,
    double size = 50,
    this.initialVelocity,
    this.onCollision,
    this.onUpdate,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'RigidBody',
    super.child,
  }) : width = size,
       height = size;

  /// Shorthand constructor for circles
  FlashRigidBody.circle({
    super.key,
    this.type = 2,
    this.shapeType = FlashPhysics.circle,
    double radius = 25,
    this.initialVelocity,
    this.onCollision,
    this.onUpdate,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'RigidBody',
    super.child,
  }) : width = radius * 2,
       height = radius * 2;

  @override
  State<FlashRigidBody> createState() => _FlashRigidBodyState();
}

class _FlashRigidBodyState extends FlashNodeWidgetState<FlashRigidBody, FlashPhysicsBody> {
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
      throw Exception('FlashRigidBody: Failed to initialize physics world');
    }

    final node = FlashPhysicsBody(
      world: activeWorld.world,
      type: widget.type,
      shapeType: widget.shapeType,
      x: widget.position?.x ?? 0,
      y: widget.position?.y ?? 0,
      width: widget.width,
      height: widget.height,
      rotation: widget.rotation?.z ?? 0,
      name: widget.name ?? 'RigidBody',
    );

    node.onCollision = widget.onCollision;
    node.onUpdate = widget.onUpdate;

    if (widget.initialVelocity != null) {
      node.setVelocity(widget.initialVelocity!.x, widget.initialVelocity!.y);
    }

    return node;
  }
}
