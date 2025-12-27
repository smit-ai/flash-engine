import 'package:flutter/material.dart';
import '../../core/systems/physics.dart';
import '../framework.dart';

/// A static physics body (e.g. floor, walls) that doesn't move.
class FlashStaticBody extends FlashNodeWidget {
  final int shapeType;
  final double width;
  final double height;
  final void Function(FlashPhysicsBody)? onCreated;
  final Color color;
  final bool debugDraw;
  final double restitution;
  final double friction;

  const FlashStaticBody({
    super.key,
    this.shapeType = FlashPhysics.box,
    this.width = 100,
    this.height = 100,
    this.onCreated,
    this.color = Colors.grey,
    this.debugDraw = false,
    this.restitution = 0.5,
    this.friction = 0.1,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'StaticBody',
    super.child,
  });

  /// Shorthand constructor for squares
  const FlashStaticBody.square({
    super.key,
    this.shapeType = FlashPhysics.box,
    double size = 100,
    this.onCreated,
    this.color = Colors.grey,
    this.debugDraw = false,
    this.restitution = 0.5,
    this.friction = 0.1,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'StaticBody',
    super.child,
  }) : width = size,
       height = size;

  /// Shorthand constructor for circles
  const FlashStaticBody.circle({
    super.key,
    double radius = 50,
    this.onCreated,
    this.color = Colors.grey,
    this.debugDraw = false,
    this.restitution = 0.5,
    this.friction = 0.1,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'StaticBody',
    super.child,
  }) : shapeType = 0, // CIRCLE
       width = radius * 2,
       height = radius * 2;

  @override
  State<FlashStaticBody> createState() => _FlashStaticBodyState();
}

class _FlashStaticBodyState extends FlashNodeWidgetState<FlashStaticBody, FlashPhysicsBody> {
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
      throw Exception('FlashStaticBody: Failed to initialize physics world');
    }

    final node = FlashPhysicsBody(
      world: activeWorld.world,
      type: 0, // STATIC
      shapeType: widget.shapeType,
      x: widget.position?.x ?? 0,
      y: widget.position?.y ?? 0,
      width: widget.width,
      height: widget.height,
      rotation: widget.rotation?.z ?? 0,
      name: widget.name ?? 'StaticBody',
      color: widget.color,
      debugDraw: widget.debugDraw,
      restitution: widget.restitution,
      friction: widget.friction,
    );

    widget.onCreated?.call(node);

    return node;
  }
}
