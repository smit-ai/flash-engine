import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

/// Abstract base class for projections.
///
/// A projection transforms 3D world coordinates to 2D screen coordinates.
/// Different projections create different visual effects:
/// - Orthographic: No perspective, parallel lines stay parallel
/// - Isometric: Pseudo-3D with fixed angle
/// - Perspective: True 3D with vanishing point
abstract class FProjection {
  const FProjection();

  /// Project a 3D world position to 2D screen coordinates.
  Offset project(Vector3 worldPos);

  /// Unproject a 2D screen position back to 3D world coordinates.
  /// The Z component is typically set to 0 (ground plane).
  Vector3 unproject(Offset screenPos, {double z = 0});

  /// Get the projection matrix (for advanced use cases).
  Matrix4 get projectionMatrix;
}

/// Orthographic projection (flat 2D view).
///
/// No perspective distortion - objects appear the same size
/// regardless of their Z coordinate. Used for:
/// - Top-down games
/// - 2D platformers
/// - UI rendering
class FOrthographicProjection extends FProjection {
  /// Zoom level (1.0 = no zoom)
  final double zoom;

  const FOrthographicProjection({this.zoom = 1.0});

  @override
  Offset project(Vector3 worldPos) {
    return Offset(worldPos.x * zoom, worldPos.y * zoom);
  }

  @override
  Vector3 unproject(Offset screenPos, {double z = 0}) {
    return Vector3(screenPos.dx / zoom, screenPos.dy / zoom, z);
  }

  @override
  Matrix4 get projectionMatrix {
    final m = Matrix4.identity();
    m[0] = zoom;
    m[5] = zoom;
    return m;
  }
}

/// Isometric projection for 2.5D games.
///
/// Creates a pseudo-3D effect by rotating the view 45 degrees
/// and tilting it. Common angles:
/// - True isometric: 30° from horizontal
/// - Dimetric: Various angles (often 26.57° for pixel-perfect)
/// - Trimetric: All axes at different angles
class FIsometricProjection extends FProjection {
  /// Angle in radians (default: 30° = π/6 for true isometric)
  final double angle;

  /// Scale factor
  final double scale;

  /// Y-axis compression (0.5 for true isometric)
  final double yRatio;

  const FIsometricProjection({
    this.angle = 0.5236, // 30 degrees
    this.scale = 1.0,
    this.yRatio = 0.5,
  });

  @override
  Offset project(Vector3 worldPos) {
    // Isometric transformation:
    // screenX = (x - y) * cos(angle)
    // screenY = (x + y) * sin(angle) - z
    final isoX = (worldPos.x - worldPos.y) * scale;
    final isoY = (worldPos.x + worldPos.y) * yRatio * scale - worldPos.z * scale;
    return Offset(isoX, isoY);
  }

  @override
  Vector3 unproject(Offset screenPos, {double z = 0}) {
    // Inverse of isometric transformation (assuming z = 0)
    final adjustedY = screenPos.dy + z * scale;
    final x = (screenPos.dx / scale + adjustedY / (yRatio * scale)) / 2;
    final y = (adjustedY / (yRatio * scale) - screenPos.dx / scale) / 2;
    return Vector3(x, y, z);
  }

  @override
  Matrix4 get projectionMatrix {
    // Approximation of isometric matrix
    return Matrix4.identity()
      ..rotateX(-0.6154) // arctan(1/sqrt(2))
      ..rotateZ(0.7854); // 45 degrees
  }
}

/// Perspective projection for true 3D.
///
/// Objects appear smaller as they get farther from the camera.
/// Uses a field of view and focal length for realistic depth.
class FPerspectiveProjection extends FProjection {
  /// Field of view in radians
  final double fov;

  /// Distance from camera to screen plane
  final double focalLength;

  /// Camera Z position (distance from origin)
  final double cameraZ;

  const FPerspectiveProjection({
    this.fov = 1.0472, // 60 degrees
    this.focalLength = 500.0,
    this.cameraZ = 500.0,
  });

  @override
  Offset project(Vector3 worldPos) {
    // Simple perspective: scale by distance from camera
    final depth = cameraZ - worldPos.z;
    if (depth <= 0) {
      // Object is behind camera
      return Offset.zero;
    }

    final scale = focalLength / depth;
    return Offset(worldPos.x * scale, worldPos.y * scale);
  }

  @override
  Vector3 unproject(Offset screenPos, {double z = 0}) {
    final depth = cameraZ - z;
    final scale = focalLength / depth;
    return Vector3(screenPos.dx / scale, screenPos.dy / scale, z);
  }

  @override
  Matrix4 get projectionMatrix {
    return Matrix4.identity()..setEntry(3, 2, -1 / focalLength);
  }
}
