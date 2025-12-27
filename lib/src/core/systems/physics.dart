import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../graph/node.dart';
import '../graph/signal.dart';
import '../native/particles_ffi.dart';
import '../native/physics_joints_ffi.dart';
import '../native/physics_ids.dart';

export '../native/physics_ids.dart'; // Export ID types (WorldId, BodyId)

class FPhysicsSystem {
  // Singleton instance of the native physics world
  final WorldId world;
  final v.Vector2 gravity;

  // Static instance of Joints FFI
  static PhysicsJointsFFI? _jointsFFI;
  static PhysicsJointsFFI? get jointsFFI {
    if (_jointsFFI == null && (Platform.isMacOS || Platform.isIOS)) {
      try {
        final lib = PhysicsJointsFFI.loadLibrary();
        _jointsFFI = PhysicsJointsFFI(lib);
      } catch (e) {
        debugPrint('⚠️ Failed to load physics joints FFI: $e');
      }
    }
    return _jointsFFI;
  }

  FPhysicsSystem({v.Vector2? gravity})
    : gravity = gravity ?? FPhysics.standardGravity,
      // Safety check for native initialization
      world = _createWorldSafe(2048) {
    // Set gravity on the world struct directly
    world.ref.gravityX = this.gravity.x;
    world.ref.gravityY = this.gravity.y;

    // OPTIMIZED PARAMETERS for stability (prevent sinking & vibration)
    // 8x Sub-stepping allows us to use very stiff springs (120Hz) stably.
    // This is critical for preventing sinking into the rigid floor.
    world.ref.contactHertz = 120.0;

    // OPTIMIZED PARAMETERS for stability (prevent sinking & vibration)
    world.ref.contactHertz = 120.0; // High stiffness to prevent sinking
    world.ref.positionIterations = 4; // Sufficient with sub-stepping
    world.ref.velocityIterations = 4;
    world.ref.contactDampingRatio = 0.5; // Standard damping

    // Joints FFI is now lazily initialized via the getter
  }

  static WorldId _createWorldSafe(int capacity) {
    // Ensure native library is loaded
    FlashNativeParticles.init();

    if (FlashNativeParticles.createPhysicsWorld == null) {
      throw UnsupportedError(
        'Native physics functions not initialized.\n'
        'Please ensure the native library is properly integrated.',
      );
    }
    return FlashNativeParticles.createPhysicsWorld!(capacity);
  }

  double _accumulator = 0.0;
  static const double _fixedDt = 1.0 / 120.0; // Run physics at 120Hz fixed

  void update(double dt) {
    // Fixed Time Step Loop
    // Accumulate time and step physics in fixed chunks.
    // This prevents instability caused by variable frame times (dt).

    // Clamp dt to avoid spiral of death
    if (dt > 0.25) dt = 0.25;

    _accumulator += dt;

    while (_accumulator >= _fixedDt) {
      FlashNativeParticles.stepPhysics!(world, _fixedDt);
      _accumulator -= _fixedDt;
    }
  }

  void dispose() {
    FlashNativeParticles.destroyPhysicsWorld!(world);
  }

  void setWarmStarting(bool enable) {
    // FlashNativeParticles.setWarmStarting!(world, enable ? 1 : 0);
  }

  // --- ID-Based API Wrappers (Static for strict separation) ---

  static BodyId createBody(
    WorldId world,
    int type,
    int shapeType,
    double x,
    double y,
    double width,
    double height,
    double rotation,
    int categoryBits,
    int maskBits,
  ) {
    return FlashNativeParticles.createBody!(
      world,
      type,
      shapeType,
      x,
      y,
      width,
      height,
      rotation,
      categoryBits,
      maskBits,
    );
  }

  static void setBodyVelocity(WorldId world, BodyId bodyId, double vx, double vy) {
    FlashNativeParticles.setBodyVelocity!(world, bodyId, vx, vy);
  }

  static void applyForce(WorldId world, BodyId bodyId, double fx, double fy) {
    FlashNativeParticles.applyForce!(world, bodyId, fx, fy);
  }

  static void applyTorque(WorldId world, BodyId bodyId, double torque) {
    FlashNativeParticles.applyTorque!(world, bodyId, torque);
  }

  static void getBodyPosition(WorldId world, BodyId bodyId, Pointer<Float> posX, Pointer<Float> posY) {
    FlashNativeParticles.getBodyPosition!(world, bodyId, posX, posY);
  }

  // Helper to access body struct safely via ID
  static Pointer<NativeBody> _getBodyPtr(WorldId world, BodyId bodyId) {
    return world.ref.bodies + bodyId;
  }

  static void setRestitution(WorldId world, BodyId bodyId, double value) {
    _getBodyPtr(world, bodyId).ref.restitution = value;
  }

  static double getRestitution(WorldId world, BodyId bodyId) {
    return _getBodyPtr(world, bodyId).ref.restitution;
  }

  static void setFriction(WorldId world, BodyId bodyId, double value) {
    _getBodyPtr(world, bodyId).ref.friction = value;
  }

  static double getFriction(WorldId world, BodyId bodyId) {
    return _getBodyPtr(world, bodyId).ref.friction;
  }

  static void setBullet(WorldId world, BodyId bodyId, bool isBullet) {
    _getBodyPtr(world, bodyId).ref.isBullet = isBullet ? 1 : 0;
  }

  static double getRotation(WorldId world, BodyId bodyId) {
    return _getBodyPtr(world, bodyId).ref.rotation;
  }

  static int getCollisionCount(WorldId world, BodyId bodyId) {
    return _getBodyPtr(world, bodyId).ref.collisionCount;
  }

  static void setCategoryBits(WorldId world, BodyId bodyId, int bits) {
    _getBodyPtr(world, bodyId).ref.categoryBits = bits;
  }

  static int getCategoryBits(WorldId world, BodyId bodyId) {
    return _getBodyPtr(world, bodyId).ref.categoryBits;
  }

  static void setMaskBits(WorldId world, BodyId bodyId, int bits) {
    _getBodyPtr(world, bodyId).ref.maskBits = bits;
  }

  static int getMaskBits(WorldId world, BodyId bodyId) {
    return _getBodyPtr(world, bodyId).ref.maskBits;
  }

  // --- RayCast ---
  static RayCastHit? rayCast(WorldId world, double fromX, double fromY, double toX, double toY) {
    if (FlashNativeParticles.rayCast == null) return null;
    final result = FlashNativeParticles.rayCast!(world, fromX, fromY, toX, toY);
    if (result.hit != 0) return result;
    return null;
  }

  // --- Soft Body API ---

  static int createSoftBody(
    WorldId world,
    int pointCount,
    Pointer<Float> initialX,
    Pointer<Float> initialY,
    double pressure,
    double stiffness,
  ) {
    if (FlashNativeParticles.createSoftBody == null) return -1;
    return FlashNativeParticles.createSoftBody!(world, pointCount, initialX, initialY, pressure, stiffness);
  }

  static void getSoftBodyPoint(WorldId world, int sbId, int pointIdx, Pointer<Float> outX, Pointer<Float> outY) {
    FlashNativeParticles.getSoftBodyPoint!(world, sbId, pointIdx, outX, outY);
  }

  static void setSoftBodyPoint(WorldId world, int sbId, int pointIdx, double x, double y) {
    FlashNativeParticles.setSoftBodyPoint!(world, sbId, pointIdx, x, y);
  }

  /// Helper to get point position as Offset without manual implementation management
  static Offset getSoftBodyPointPos(WorldId world, int sbId, int pointIdx) {
    final ptrX = calloc<Float>();
    final ptrY = calloc<Float>();

    FlashNativeParticles.getSoftBodyPoint!(world, sbId, pointIdx, ptrX, ptrY);

    final x = ptrX.value;
    final y = ptrY.value;

    calloc.free(ptrX);
    calloc.free(ptrY);

    return Offset(x, y);
  }

  static void setSoftBodyParams(WorldId world, int sbId, double pressure, double stiffness) {
    FlashNativeParticles.setSoftBodyParams!(world, sbId, pressure, stiffness);
  }
}

class FPhysics {
  // Conversion constants
  static const double pixelsToMeters = 1.0 / 50.0;
  static const double metersToPixels = 50.0;
  // FlashPainter uses Y-Up coordinate system (0,0 in center, +Y is Up).
  // So Gravity must be negative to pull things down.
  static final v.Vector2 standardGravity = v.Vector2(0, -9.81 * 100);

  // Body Types
  static const int staticBody = 0;
  static const int kinematicBody = 1;
  static const int dynamicBody = 2;

  // Shapes
  static const int circle = 0;
  static const int box = 1;
}

class FPhysicsBody extends FNode {
  final double width;
  final double height;
  final double rotation;
  Color color;

  // Internal body ID from native physics
  final BodyId bodyId;
  final int shapeType; // Store the shape type for correct rendering
  final WorldId _world;

  // -- Signals --

  /// Emitted when this body collides
  final FSignal<FPhysicsBody> collision = FSignal();

  /// Emitted on every physics update
  final FSignal<FPhysicsBody> physicsProcess = FSignal();

  // Temporary buffers to avoid allocation in sync
  static final Pointer<Float> _posX = calloc<Float>();
  static final Pointer<Float> _posY = calloc<Float>();

  // Mutable debug flag
  bool debugDraw;

  FPhysicsBody({
    required WorldId world,
    int type = 2, // DYNAMIC
    this.shapeType = FPhysics.circle,
    double x = 0,
    double y = 0,
    this.width = 50,
    this.height = 50,
    this.rotation = 0,
    super.name = 'PhysicsBody',
    this.color = Colors.white,
    this.debugDraw = false,
    double restitution = 0.5,
    double friction = 0.1,
    int categoryBits = 0x0001,
    int maskBits = 0xFFFF,
  }) : _world = world,
       bodyId = FPhysicsSystem.createBody(
         world,
         type,
         shapeType,
         x,
         y,
         width,
         height,
         rotation,
         categoryBits,
         maskBits,
       ) {
    this.restitution = restitution;
    this.friction = friction;
    _syncFromPhysics();
  }

  /// Get/Set Collision Category Bits
  int get categoryBits => FPhysicsSystem.getCategoryBits(_world, bodyId);
  set categoryBits(int value) => FPhysicsSystem.setCategoryBits(_world, bodyId, value);

  /// Get/Set Collision Mask Bits
  int get maskBits => FPhysicsSystem.getMaskBits(_world, bodyId);
  set maskBits(int value) => FPhysicsSystem.setMaskBits(_world, bodyId, value);

  /// Get/Set Restitution (Bounciness) directly on native body
  double get restitution => FPhysicsSystem.getRestitution(_world, bodyId);
  set restitution(double value) => FPhysicsSystem.setRestitution(_world, bodyId, value);

  /// Get/Set Friction directly on native body
  double get friction => FPhysicsSystem.getFriction(_world, bodyId);
  set friction(double value) => FPhysicsSystem.setFriction(_world, bodyId, value);

  /// Get the native physics world pointer
  WorldId get world => _world;

  @override
  void draw(Canvas canvas) {
    if (!debugDraw) return;

    final paint = Paint()..color = color;

    if (shapeType == FPhysics.circle) {
      canvas.drawCircle(Offset.zero, width / 2, paint);
    } else {
      final visibleRect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
      canvas.drawRect(visibleRect, paint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncFromPhysics();
    physicsProcess.emit(this);
  }

  void setVelocity(double vx, double vy) {
    FPhysicsSystem.setBodyVelocity(_world, bodyId, vx, vy);
  }

  void applyForce(double fx, double fy) {
    FPhysicsSystem.applyForce(_world, bodyId, fx, fy);
  }

  void applyTorque(double torque) {
    FPhysicsSystem.applyTorque(_world, bodyId, torque);
  }

  /// Enable continuous collision detection for fast-moving bodies
  void setBullet(bool isBullet) {
    FPhysicsSystem.setBullet(_world, bodyId, isBullet);
  }

  void _syncFromPhysics() {
    FPhysicsSystem.getBodyPosition(_world, bodyId, _posX, _posY);
    final rot = FPhysicsSystem.getRotation(_world, bodyId);

    if (_posX.value.isNaN || _posY.value.isNaN || rot.isNaN) {
      return;
    }

    transform.position = v.Vector3(_posX.value, _posY.value, 0);
    transform.rotation = v.Vector3(0, 0, rot);

    // Check for collisions (feedback from native core)
    if (FPhysicsSystem.getCollisionCount(_world, bodyId) > 0) {
      collision.emit(this);
    }
  }

  @override
  Rect? get bounds {
    // If shape is circle, we still return a square bounding box for culling.
    return Rect.fromCenter(center: Offset.zero, width: width, height: height);
  }
}

class FSoftBody extends FNode {
  final int id;
  final WorldId world;
  final int pointCount;
  final List<Offset> points;

  // Temp buffers for syncing
  static final Pointer<Float> _pointX = calloc<Float>();
  static final Pointer<Float> _pointY = calloc<Float>();

  FSoftBody({
    required this.world,
    required List<Offset> initialPoints,
    double pressure = 1.0,
    double stiffness = 1.0,
    super.name = 'SoftBody',
  }) : pointCount = initialPoints.length,
       points = List.from(initialPoints),
       id = _createNative(world, initialPoints, pressure, stiffness);

  static int _createNative(WorldId world, List<Offset> initialPoints, double pressure, double stiffness) {
    final count = initialPoints.length;
    final ptrX = calloc<Float>(count);
    final ptrY = calloc<Float>(count);

    for (int i = 0; i < count; i++) {
      ptrX[i] = initialPoints[i].dx;
      ptrY[i] = initialPoints[i].dy;
    }

    final id = FPhysicsSystem.createSoftBody(world, count, ptrX, ptrY, pressure, stiffness);

    calloc.free(ptrX);
    calloc.free(ptrY);
    return id;
  }

  void setParams(double pressure, double stiffness) {
    FPhysicsSystem.setSoftBodyParams(world, id, pressure, stiffness);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncFromNative();
  }

  void _syncFromNative() {
    for (int i = 0; i < pointCount; i++) {
      FPhysicsSystem.getSoftBodyPoint(world, id, i, _pointX, _pointY);
      points[i] = Offset(_pointX.value, _pointY.value);
    }
  }

  @override
  void draw(Canvas canvas) {
    // Basic debug draw
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
    }
    canvas.drawPath(path, paint);
  }
}

/// Helper class for defining collision layers (Legacy/UI compatibility)
class FCollisionLayer {
  static const int none = 0x0000;
  static const int all = 0xFFFF;
  static int maskOf(List<int> layers) {
    int mask = 0;
    for (final layer in layers) {
      mask |= (1 << layer);
    }
    return mask;
  }
}
