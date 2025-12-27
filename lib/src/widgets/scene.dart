import 'package:flutter/widgets.dart';
import '../core/systems/engine.dart';
import '../core/systems/physics.dart';
import 'framework.dart';
import '../../flash_view.dart';

/// FScene - A clean separation between Flash 3D scene and Flutter UI overlay.
///
/// Use either `scene` (static) or `sceneBuilder` (dynamic with elapsed time).
///
/// The `overlay` children are regular Flutter widgets (Positioned, Text, etc.)
/// that render on top of the scene.
///
/// Example (static):
/// ```dart
/// FScene(
///   scene: [FCamera(...), FCircle(...)],
///   overlay: [Positioned(...)],
/// )
/// ```
///
/// Example (dynamic with elapsed):
/// ```dart
/// FScene(
///   sceneBuilder: (context, elapsed) => [
///     FCamera(...),
///     FBox(rotation: v.Vector3(0, elapsed, 0)),
///   ],
///   overlay: [Positioned(...)],
/// )
/// ```
class FScene extends StatelessWidget {
  /// Static Flash scene widgets (Z-sorted automatically).
  /// Use this OR [sceneBuilder], not both.
  final List<Widget>? scene;

  /// Dynamic scene builder with elapsed time (in seconds).
  /// Use this OR [scene], not both.
  final List<Widget> Function(BuildContext context, double elapsed)? sceneBuilder;

  /// Flutter UI overlay widgets (rendered on top).
  final List<Widget> overlay;

  /// Physics world to use for this scene.
  final FPhysicsSystem? physicsWorld;

  /// If true, auto-updates every frame (60 FPS).
  final bool autoUpdate;

  /// Show FPS and node count debug overlay.
  final bool showDebugOverlay;

  /// Enable keyboard/pointer input capture.
  final bool enableInputCapture;

  /// Called once when the engine is ready for one-time setup.
  final void Function(FEngine engine)? onReady;

  /// Called every frame.
  final VoidCallback? onUpdate;

  const FScene({
    super.key,
    this.scene,
    this.sceneBuilder,
    this.overlay = const [],
    this.physicsWorld,
    this.autoUpdate = true,
    this.showDebugOverlay = true,
    this.enableInputCapture = true,
    this.onReady,
    this.onUpdate,
  }) : assert(scene != null || sceneBuilder != null, 'Either scene or sceneBuilder must be provided');

  @override
  Widget build(BuildContext context) {
    return FView(
      physicsWorld: physicsWorld,
      autoUpdate: autoUpdate,
      showDebugOverlay: showDebugOverlay,
      enableInputCapture: enableInputCapture,
      onReady: onReady,
      onUpdate: onUpdate,
      child: Builder(
        builder: (innerContext) {
          final engine = innerContext.flash;
          final elapsed = engine?.elapsed ?? 0.0;

          // Use sceneBuilder if provided, otherwise use static scene
          final sceneWidgets = sceneBuilder != null ? sceneBuilder!(innerContext, elapsed) : (scene ?? const []);

          return Stack(
            children: [
              // Scene layer - Flash widgets with Z-sorting
              ...sceneWidgets,
              // Overlay layer - Flutter UI on top
              ...overlay,
            ],
          );
        },
      ),
    );
  }
}
