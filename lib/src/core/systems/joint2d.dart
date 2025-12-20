import 'package:forge2d/forge2d.dart' as f2d;
import 'physics.dart';

/// Base class for physics joints (Godot-style)
abstract class FlashJoint2D {
  final FlashPhysicsBody bodyA;
  final FlashPhysicsBody? bodyB;
  f2d.Joint? _joint;

  FlashJoint2D({required this.bodyA, this.bodyB});

  f2d.Joint? get joint => _joint;

  /// Create the joint in the physics world
  void create(FlashPhysicsSystem world);

  /// Destroy the joint
  void destroy(FlashPhysicsSystem world) {
    if (_joint != null) {
      world.world.destroyJoint(_joint!);
      _joint = null;
    }
  }

  bool get isActive => _joint != null;
}

/// Revolute joint - rotation around anchor point
/// Works like Godot's PinJoint2D
class FlashRevoluteJoint2D extends FlashJoint2D {
  final Vector2 anchorWorldPoint;
  final bool enableMotor;
  final double motorSpeed;
  final double maxMotorTorque;
  final bool enableLimit;
  final double lowerAngle;
  final double upperAngle;

  FlashRevoluteJoint2D({
    required super.bodyA,
    super.bodyB,
    required this.anchorWorldPoint,
    this.enableMotor = false,
    this.motorSpeed = 0,
    this.maxMotorTorque = 100,
    this.enableLimit = false,
    this.lowerAngle = 0,
    this.upperAngle = 0,
  });

  @override
  void create(FlashPhysicsSystem world) {
    final bodyBRef = bodyB?.body ?? bodyA.body; // If no bodyB, use bodyA (pinned to world)

    final def = f2d.RevoluteJointDef()
      ..bodyA = bodyA.body
      ..bodyB = bodyBRef
      ..localAnchorA.setFrom(bodyA.body.localPoint(anchorWorldPoint))
      ..localAnchorB.setFrom(bodyBRef.localPoint(anchorWorldPoint))
      ..enableMotor = enableMotor
      ..motorSpeed = motorSpeed
      ..maxMotorTorque = maxMotorTorque
      ..enableLimit = enableLimit
      ..lowerAngle = lowerAngle
      ..upperAngle = upperAngle
      ..collideConnected = false;

    _joint = f2d.RevoluteJoint(def);
    world.world.createJoint(_joint!);
  }

  double get angle => (_joint as f2d.RevoluteJoint?)?.jointAngle() ?? 0;
}

/// Distance joint - spring connection between two bodies
class FlashDistanceJoint2D extends FlashJoint2D {
  final Vector2 anchorA;
  final Vector2 anchorB;
  final double? length;

  FlashDistanceJoint2D({required super.bodyA, super.bodyB, required this.anchorA, required this.anchorB, this.length});

  @override
  void create(FlashPhysicsSystem world) {
    final bodyBRef = bodyB?.body ?? bodyA.body;

    final def = f2d.DistanceJointDef()
      ..bodyA = bodyA.body
      ..bodyB = bodyBRef
      ..localAnchorA.setFrom(anchorA)
      ..localAnchorB.setFrom(anchorB)
      ..collideConnected = false;

    if (length != null) {
      def.length = length!;
    } else {
      // Auto-calculate length
      final worldA = bodyA.body.worldPoint(anchorA);
      final worldB = bodyBRef.worldPoint(anchorB);
      def.length = (worldB - worldA).length;
    }

    _joint = f2d.DistanceJoint(def);
    world.world.createJoint(_joint!);
  }
}

/// Weld joint - rigidly connects two bodies
class FlashWeldJoint2D extends FlashJoint2D {
  final Vector2 anchorWorldPoint;

  FlashWeldJoint2D({required super.bodyA, required FlashPhysicsBody super.bodyB, required this.anchorWorldPoint});

  @override
  void create(FlashPhysicsSystem world) {
    final def = f2d.WeldJointDef()
      ..bodyA = bodyA.body
      ..bodyB = bodyB!.body
      ..localAnchorA.setFrom(bodyA.body.localPoint(anchorWorldPoint))
      ..localAnchorB.setFrom(bodyB!.body.localPoint(anchorWorldPoint))
      ..referenceAngle = bodyB!.body.angle - bodyA.body.angle
      ..collideConnected = false;

    _joint = f2d.WeldJoint(def);
    world.world.createJoint(_joint!);
  }
}

/// Prismatic joint - slider along an axis
class FlashPrismaticJoint2D extends FlashJoint2D {
  final Vector2 anchorWorldPoint;
  final Vector2 axis;
  final bool enableLimit;
  final double lowerTranslation;
  final double upperTranslation;
  final bool enableMotor;
  final double motorSpeed;
  final double maxMotorForce;

  FlashPrismaticJoint2D({
    required super.bodyA,
    super.bodyB,
    required this.anchorWorldPoint,
    required this.axis,
    this.enableLimit = false,
    this.lowerTranslation = 0,
    this.upperTranslation = 0,
    this.enableMotor = false,
    this.motorSpeed = 0,
    this.maxMotorForce = 100,
  });

  @override
  void create(FlashPhysicsSystem world) {
    final bodyBRef = bodyB?.body ?? bodyA.body;

    final def = f2d.PrismaticJointDef()
      ..bodyA = bodyA.body
      ..bodyB = bodyBRef
      ..localAnchorA.setFrom(bodyA.body.localPoint(anchorWorldPoint))
      ..localAnchorB.setFrom(bodyBRef.localPoint(anchorWorldPoint))
      ..localAxisA.setFrom(axis.normalized())
      ..enableLimit = enableLimit
      ..lowerTranslation = lowerTranslation
      ..upperTranslation = upperTranslation
      ..enableMotor = enableMotor
      ..motorSpeed = motorSpeed
      ..maxMotorForce = maxMotorForce
      ..collideConnected = false;

    _joint = f2d.PrismaticJoint(def);
    world.world.createJoint(_joint!);
  }

  double get translation => (_joint as f2d.PrismaticJoint?)?.getJointTranslation() ?? 0;
}

/// Pulley joint - simulates a pulley system
class FlashPulleyJoint2D extends FlashJoint2D {
  final Vector2 groundAnchorA;
  final Vector2 groundAnchorB;
  final Vector2 localAnchorA;
  final Vector2 localAnchorB;
  final double ratio;

  FlashPulleyJoint2D({
    required super.bodyA,
    required FlashPhysicsBody super.bodyB,
    required this.groundAnchorA,
    required this.groundAnchorB,
    required this.localAnchorA,
    required this.localAnchorB,
    this.ratio = 1.0,
  });

  @override
  void create(FlashPhysicsSystem world) {
    final def = f2d.PulleyJointDef()
      ..bodyA = bodyA.body
      ..bodyB = bodyB!.body
      ..groundAnchorA.setFrom(groundAnchorA)
      ..groundAnchorB.setFrom(groundAnchorB)
      ..localAnchorA.setFrom(localAnchorA)
      ..localAnchorB.setFrom(localAnchorB)
      ..ratio = ratio
      ..collideConnected = false;

    _joint = f2d.PulleyJoint(def);
    world.world.createJoint(_joint!);
  }
}

/// Joint manager for the physics world
class FlashJoint2DManager {
  final FlashPhysicsSystem world;
  final List<FlashJoint2D> _joints = [];

  FlashJoint2DManager(this.world);

  void add(FlashJoint2D joint) {
    joint.create(world);
    _joints.add(joint);
  }

  void remove(FlashJoint2D joint) {
    joint.destroy(world);
    _joints.remove(joint);
  }

  void clear() {
    for (final joint in _joints) {
      joint.destroy(world);
    }
    _joints.clear();
  }

  int get count => _joints.length;
  List<FlashJoint2D> get joints => List.unmodifiable(_joints);
}
