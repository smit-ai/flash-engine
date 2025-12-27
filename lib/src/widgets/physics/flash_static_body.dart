import 'package:flutter/material.dart';
import '../../core/systems/physics.dart';
import '../framework.dart';

/// A static physics body (e.g. floor, walls) that doesn't move.
class FStaticBody extends FNodeWidget {
  final int shapeType;
  final double width;
  final double height;
  final void Function(FPhysicsBody)? onCreated;
  final Color color;
  final bool debugDraw;
  final double restitution;
  final double friction;
  final int? categoryBits;
  final int? maskBits;

  const FStaticBody({
    super.key,
    this.shapeType = FPhysics.box,
    this.width = 100,
    this.height = 100,
    this.onCreated,
    this.color = Colors.grey,
    this.debugDraw = false,
    this.restitution = 0.5,
    this.friction = 0.1,
    this.categoryBits,
    this.maskBits,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'StaticBody',
    super.child,
  });

  /// Shorthand constructor for squares
  const FStaticBody.square({
    super.key,
    this.shapeType = FPhysics.box,
    double size = 100,
    this.onCreated,
    this.color = Colors.grey,
    this.debugDraw = false,
    this.restitution = 0.5,
    this.friction = 0.1,
    this.categoryBits,
    this.maskBits,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'StaticBody',
    super.child,
  }) : width = size,
       height = size;

  /// Shorthand constructor for circles
  const FStaticBody.circle({
    super.key,
    double radius = 50,
    this.onCreated,
    this.color = Colors.grey,
    this.debugDraw = false,
    this.restitution = 0.5,
    this.friction = 0.1,
    this.categoryBits,
    this.maskBits,
    super.position,
    super.rotation,
    super.scale,
    super.name = 'StaticBody',
    super.child,
  }) : shapeType = 0, // CIRCLE
       width = radius * 2,
       height = radius * 2;

  @override
  State<FStaticBody> createState() => _FStaticBodyState();
}

class _FStaticBodyState extends FNodeWidgetState<FStaticBody, FPhysicsBody> {
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
      throw Exception('FStaticBody: Failed to initialize physics world');
    }

    final node = FPhysicsBody(
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
      categoryBits: widget.categoryBits ?? 0x0001,
      maskBits: widget.maskBits ?? 0xFFFF,
    );

    widget.onCreated?.call(node);

    return node;
  }
}
