import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart' as f2d;
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

class FlashRigidBody extends FlashNodeWidget {
  final f2d.BodyDef? bodyDef;
  final List<f2d.FixtureDef>? fixtures;
  final void Function(f2d.Contact)? onCollision;
  final void Function(f2d.Contact)? onCollisionEnd;
  final void Function(f2d.Body)? onUpdate;

  /// Collision category (bitwise)
  final int category;

  /// Collision mask (bitwise)
  final int mask;

  const FlashRigidBody({
    super.key,
    this.bodyDef,
    this.fixtures,
    this.onCollision,
    this.onCollisionEnd,
    this.onUpdate,
    this.category = FlashCollisionLayer.layer1,
    this.mask = FlashCollisionLayer.all,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    super.child,
  });

  @override
  State<FlashRigidBody> createState() => _FlashRigidBodyState();
}

class _FlashRigidBodyState extends FlashNodeWidgetState<FlashRigidBody, FlashPhysicsBody> {
  @override
  void didUpdateWidget(FlashRigidBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category || widget.mask != oldWidget.mask) {
      _updateFilters();
    }
  }

  void _updateFilters() {
    for (final fixture in node.body.fixtures) {
      final filter = f2d.Filter()
        ..categoryBits = widget.category
        ..maskBits = widget.mask;
      fixture.filterData = filter;
    }
  }

  @override
  FlashPhysicsBody createNode() {
    final element = context.getElementForInheritedWidgetOfExactType<InheritedFlashNode>();
    final engine = (element?.widget as InheritedFlashNode?)?.engine;
    final world = engine?.physicsWorld;

    if (world == null) {
      throw Exception('FlashRigidBody requires a FlashPhysicsWorld in the Flash engine');
    }

    final bodyDef = widget.bodyDef ?? (f2d.BodyDef()..type = f2d.BodyType.dynamic);
    if (widget.position != null) {
      bodyDef.position = f2d.Vector2(
        FlashPhysics.toMeters(widget.position!.x),
        FlashPhysics.toMeters(widget.position!.y),
      );
    }
    if (widget.rotation != null) {
      bodyDef.angle = widget.rotation!.z;
    }

    // Scale linear velocity from pixels to meters (safe conversion between 32/64 bit)
    final pxVelX = bodyDef.linearVelocity.x;
    final pxVelY = bodyDef.linearVelocity.y;
    bodyDef.linearVelocity.setValues(FlashPhysics.toMeters(pxVelX), FlashPhysics.toMeters(pxVelY));

    final body = world.world.createBody(bodyDef);
    if (widget.fixtures != null) {
      for (final fixtureDef in widget.fixtures!) {
        // Automatically scale fixture shapes from pixels to meters
        _scaleShape(fixtureDef.shape);

        // Apply collision filters to fixtures
        fixtureDef.filter.categoryBits = widget.category;
        fixtureDef.filter.maskBits = widget.mask;
        body.createFixture(fixtureDef);
      }
    }

    final node = FlashPhysicsBody(body: body);
    node.onCollisionStart = widget.onCollision;
    node.onCollisionEnd = widget.onCollisionEnd;
    node.onUpdate = widget.onUpdate;
    return node;
  }

  void _scaleShape(f2d.Shape shape) {
    if (shape is f2d.PolygonShape) {
      for (final vertex in shape.vertices) {
        vertex.setValues(FlashPhysics.toMeters(vertex.x), FlashPhysics.toMeters(vertex.y));
      }
    } else if (shape is f2d.CircleShape) {
      shape.radius = FlashPhysics.toMeters(shape.radius);
      shape.position.setValues(FlashPhysics.toMeters(shape.position.x), FlashPhysics.toMeters(shape.position.y));
    } else if (shape is f2d.EdgeShape) {
      shape.vertex1.setValues(FlashPhysics.toMeters(shape.vertex1.x), FlashPhysics.toMeters(shape.vertex1.y));
      shape.vertex2.setValues(FlashPhysics.toMeters(shape.vertex2.x), FlashPhysics.toMeters(shape.vertex2.y));
    } else if (shape is f2d.ChainShape) {
      for (final vertex in shape.vertices) {
        vertex.setValues(FlashPhysics.toMeters(vertex.x), FlashPhysics.toMeters(vertex.y));
      }
    }
  }
}
