import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

/// Behavior mode for camera following.
enum CameraFollowMode {
  /// No following, camera stays in place
  none,

  /// Instant snap to target
  instant,

  /// Smooth lerp following
  smooth,

  /// Lock to target with dead zone
  deadZone,
}

/// A 2D camera for grid-based games.
///
/// Provides:
/// - Position and zoom control
/// - Smooth follow behavior
/// - Dead zone support
/// - Screen shake
/// - Bounds clamping
class FGridCamera {
  /// Camera position in world coordinates
  Vector2 position;

  /// Zoom level (1.0 = normal)
  double zoom;

  /// Rotation in radians
  double rotation;

  /// Target to follow (if any)
  Vector2? target;

  /// Follow behavior
  CameraFollowMode followMode;

  /// Lerp speed for smooth following (0.0 - 1.0)
  double lerpSpeed;

  /// Dead zone rectangle (in screen space, centered)
  Rect? deadZone;

  /// Camera bounds (in world coordinates)
  Rect? bounds;

  /// Current shake offset
  final Vector2 _shakeOffset = Vector2.zero();
  double _shakeDuration = 0;
  double _shakeMagnitude = 0;

  FGridCamera({
    Vector2? position,
    this.zoom = 1.0,
    this.rotation = 0.0,
    this.target,
    this.followMode = CameraFollowMode.smooth,
    this.lerpSpeed = 0.1,
    this.deadZone,
    this.bounds,
  }) : position = position ?? Vector2.zero();

  /// Update camera (call every frame)
  void update(double dt) {
    // Handle following
    if (target != null && followMode != CameraFollowMode.none) {
      _updateFollow(dt);
    }

    // Handle shake
    if (_shakeDuration > 0) {
      _updateShake(dt);
    }

    // Clamp to bounds
    if (bounds != null) {
      _clampToBounds();
    }
  }

  void _updateFollow(double dt) {
    final t = target!;

    switch (followMode) {
      case CameraFollowMode.instant:
        position.setFrom(t);
        break;

      case CameraFollowMode.smooth:
        // Lerp towards target
        final dx = t.x - position.x;
        final dy = t.y - position.y;
        position.x += dx * lerpSpeed;
        position.y += dy * lerpSpeed;
        break;

      case CameraFollowMode.deadZone:
        if (deadZone != null) {
          // Only move if target is outside dead zone
          final halfW = deadZone!.width / 2 / zoom;
          final halfH = deadZone!.height / 2 / zoom;

          if (t.x < position.x - halfW) {
            position.x = t.x + halfW;
          } else if (t.x > position.x + halfW) {
            position.x = t.x - halfW;
          }

          if (t.y < position.y - halfH) {
            position.y = t.y + halfH;
          } else if (t.y > position.y + halfH) {
            position.y = t.y - halfH;
          }
        }
        break;

      case CameraFollowMode.none:
        break;
    }
  }

  void _updateShake(double dt) {
    _shakeDuration -= dt;

    if (_shakeDuration <= 0) {
      _shakeOffset.setZero();
      _shakeDuration = 0;
    } else {
      // Random shake offset
      _shakeOffset.x = ((_shakeDuration.hashCode % 1000) / 500 - 1) * _shakeMagnitude;
      _shakeOffset.y = (((_shakeDuration * 7).hashCode % 1000) / 500 - 1) * _shakeMagnitude;
    }
  }

  void _clampToBounds() {
    if (bounds == null) return;

    position.x = position.x.clamp(bounds!.left, bounds!.right);
    position.y = position.y.clamp(bounds!.top, bounds!.bottom);
  }

  /// Start screen shake effect
  void shake({double magnitude = 10.0, double duration = 0.3}) {
    _shakeMagnitude = magnitude;
    _shakeDuration = duration;
  }

  /// Get the effective camera position (including shake)
  Vector2 get effectivePosition {
    return Vector2(position.x + _shakeOffset.x, position.y + _shakeOffset.y);
  }

  /// Transform a world position to screen position
  Offset worldToScreen(Vector2 worldPos, Size viewport) {
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final eff = effectivePosition;

    final dx = (worldPos.x - eff.x) * zoom;
    final dy = (worldPos.y - eff.y) * zoom;

    return Offset(center.dx + dx, center.dy + dy); // Y-down (screen standard)
  }

  /// Transform a screen position to world position
  Vector2 screenToWorld(Offset screenPos, Size viewport) {
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final eff = effectivePosition;

    final dx = (screenPos.dx - center.dx) / zoom;
    final dy = (screenPos.dy - center.dy) / zoom;

    return Vector2(eff.x + dx, eff.y + dy);
  }

  /// Get the visible world rectangle
  Rect getVisibleRect(Size viewport) {
    final halfW = (viewport.width / 2) / zoom;
    final halfH = (viewport.height / 2) / zoom;
    final eff = effectivePosition;

    return Rect.fromLTRB(eff.x - halfW, eff.y - halfH, eff.x + halfW, eff.y + halfH);
  }

  /// Get the transformation matrix for canvas
  Matrix4 getTransformMatrix(Size viewport) {
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final eff = effectivePosition;

    return Matrix4.identity()
      ..setTranslationRaw(center.dx, center.dy, 0)
      ..scale(zoom, zoom, 1.0) // Y-down standard
      ..translate(-eff.x, -eff.y);
  }
}
