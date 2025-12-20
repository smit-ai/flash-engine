import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../../core/systems/physics.dart';
import '../../core/systems/joint2d.dart';
import '../framework.dart';

/// Declarative widget for creating physics joints between bodies
abstract class FlashJointWidget extends StatefulWidget {
  /// Name of bodyA in the scene
  final String bodyAName;

  /// Name of bodyB in the scene (optional for single-body joints)
  final String? bodyBName;

  /// Whether joint should be created automatically
  final bool autoCreate;

  const FlashJointWidget({super.key, required this.bodyAName, this.bodyBName, this.autoCreate = true});
}

abstract class FlashJointWidgetState<T extends FlashJointWidget> extends State<T> {
  FlashJoint2D? _joint;
  FlashPhysicsWorld? _world;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryCreateJoint();
  }

  void _tryCreateJoint() {
    if (!widget.autoCreate || _joint != null) return;

    final inherited = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
    final engine = inherited?.engine;
    _world = engine?.physicsWorld;

    if (_world == null) return;

    final bodyA = _findBodyByName(widget.bodyAName);
    final bodyB = widget.bodyBName != null ? _findBodyByName(widget.bodyBName!) : null;

    if (bodyA != null) {
      _joint = createJoint(bodyA, bodyB);
      _joint?.create(_world!);
    }
  }

  FlashPhysicsBody? _findBodyByName(String name) {
    return null; // Override to implement search
  }

  /// Override to create specific joint type
  FlashJoint2D createJoint(FlashPhysicsBody bodyA, FlashPhysicsBody? bodyB);

  @override
  void dispose() {
    if (_joint != null && _world != null) {
      _joint!.destroy(_world!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Declarative revolute joint widget (rotation around anchor)
class FlashRevoluteJointWidget extends FlashJointWidget {
  final v.Vector2 anchorWorldPoint;
  final bool enableMotor;
  final double motorSpeed;
  final double maxMotorTorque;
  final bool enableLimit;
  final double lowerAngle;
  final double upperAngle;
  final FlashPhysicsBody? bodyA;
  final FlashPhysicsBody? bodyB;

  const FlashRevoluteJointWidget({
    super.key,
    super.bodyAName = '',
    super.bodyBName,
    required this.anchorWorldPoint,
    this.enableMotor = false,
    this.motorSpeed = 0,
    this.maxMotorTorque = 100,
    this.enableLimit = false,
    this.lowerAngle = 0,
    this.upperAngle = 0,
    this.bodyA,
    this.bodyB,
  });

  @override
  State<FlashRevoluteJointWidget> createState() => _FlashRevoluteJointWidgetState();
}

class _FlashRevoluteJointWidgetState extends FlashJointWidgetState<FlashRevoluteJointWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.bodyA != null && _joint == null) {
      final inherited = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
      _world = inherited?.engine.physicsWorld;
      if (_world != null) {
        _joint = createJoint(widget.bodyA!, widget.bodyB);
        _joint?.create(_world!);
      }
    }
  }

  @override
  FlashJoint2D createJoint(FlashPhysicsBody bodyA, FlashPhysicsBody? bodyB) {
    return FlashRevoluteJoint2D(
      bodyA: bodyA,
      bodyB: bodyB,
      anchorWorldPoint: widget.anchorWorldPoint,
      enableMotor: widget.enableMotor,
      motorSpeed: widget.motorSpeed,
      maxMotorTorque: widget.maxMotorTorque,
      enableLimit: widget.enableLimit,
      lowerAngle: widget.lowerAngle,
      upperAngle: widget.upperAngle,
    );
  }
}

/// Declarative distance joint widget (spring connection)
class FlashDistanceJointWidget extends FlashJointWidget {
  final v.Vector2 anchorA;
  final v.Vector2 anchorB;
  final double? length;
  final FlashPhysicsBody? bodyA;
  final FlashPhysicsBody? bodyB;

  const FlashDistanceJointWidget({
    super.key,
    super.bodyAName = '',
    super.bodyBName,
    required this.anchorA,
    required this.anchorB,
    this.length,
    this.bodyA,
    this.bodyB,
  });

  @override
  State<FlashDistanceJointWidget> createState() => _FlashDistanceJointWidgetState();
}

class _FlashDistanceJointWidgetState extends FlashJointWidgetState<FlashDistanceJointWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.bodyA != null && _joint == null) {
      final inherited = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
      _world = inherited?.engine.physicsWorld;
      if (_world != null) {
        _joint = createJoint(widget.bodyA!, widget.bodyB);
        _joint?.create(_world!);
      }
    }
  }

  @override
  FlashJoint2D createJoint(FlashPhysicsBody bodyA, FlashPhysicsBody? bodyB) {
    return FlashDistanceJoint2D(
      bodyA: bodyA,
      bodyB: bodyB,
      anchorA: widget.anchorA,
      anchorB: widget.anchorB,
      length: widget.length,
    );
  }
}

/// Declarative weld joint widget (rigid connection)
class FlashWeldJointWidget extends FlashJointWidget {
  final v.Vector2 anchorWorldPoint;
  final FlashPhysicsBody? bodyA;
  final FlashPhysicsBody? bodyB;

  const FlashWeldJointWidget({
    super.key,
    super.bodyAName = '',
    super.bodyBName,
    required this.anchorWorldPoint,
    this.bodyA,
    this.bodyB,
  });

  @override
  State<FlashWeldJointWidget> createState() => _FlashWeldJointWidgetState();
}

class _FlashWeldJointWidgetState extends FlashJointWidgetState<FlashWeldJointWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.bodyA != null && widget.bodyB != null && _joint == null) {
      final inherited = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
      _world = inherited?.engine.physicsWorld;
      if (_world != null) {
        _joint = createJoint(widget.bodyA!, widget.bodyB);
        _joint?.create(_world!);
      }
    }
  }

  @override
  FlashJoint2D createJoint(FlashPhysicsBody bodyA, FlashPhysicsBody? bodyB) {
    return FlashWeldJoint2D(bodyA: bodyA, bodyB: bodyB!, anchorWorldPoint: widget.anchorWorldPoint);
  }
}
