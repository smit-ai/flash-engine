import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as v;

import '../graph/node.dart';
import '../graph/tree.dart';
import '../rendering/camera.dart';
import '../rendering/light.dart';
import '../systems/physics.dart';
import '../systems/particle.dart';
import '../native/particles_ffi.dart';
import 'audio.dart';
import 'input.dart';
import 'scene_manager.dart';
import 'tween.dart';

class FEngine extends ChangeNotifier {
  final FSceneTree tree = FSceneTree();
  FNode get scene => tree.root;

  final FAudioSystem audio = FAudioSystem();
  final FInputSystem input = FInputSystem();
  final FSceneManager sceneManager = FSceneManager();
  final FTweenManager tweenManager = FTweenManager();

  /// Current viewport size in pixels
  v.Vector2 viewportSize = v.Vector2(0, 0);

  FCameraNode? activeCamera;
  FPhysicsSystem? physicsWorld;
  FCameraNode? _defaultCamera;
  final Set<FCameraNode> _activeCameras = {};

  // cached render lists to avoid allocation
  final List<FNode> renderNodes = [];
  final List<FLightNode> lights = [];
  final List<FParticleEmitter> emitters = [];

  late final Ticker _ticker;

  VoidCallback? onUpdate;
  double _lastTime = 0.0;
  int tickerCount = 0;
  double fps = 0.0;
  int _frameCount = 0;
  double _fpsLastMeasureTime = 0.0;

  FEngine() {
    // Ensure native libraries are loaded
    try {
      FlashNativeParticles.init();
    } catch (e) {
      print('Failed to initialize native particles: $e');
    }
    _ticker = Ticker(_tick);
  }

  /// Register a camera when it's added to the scene
  void registerCamera(FCameraNode camera) {
    _activeCameras.add(camera);
  }

  /// Unregister a camera when it's removed from the scene
  void unregisterCamera(FCameraNode camera) {
    _activeCameras.remove(camera);
  }

  void start() {
    audio.init();
    FlashNativeParticles.init();
    _ticker.start();
  }

  void stop() {
    _ticker.stop();
    // Do NOT dispose audio here if we want to restart?
    // But stop() is called by Flash.dispose().
    // We should clean up scene first
    scene.dispose(); // Stops all audio nodes
    audio.dispose();
  }

  @override
  void dispose() {
    physicsWorld?.dispose();
    _ticker.dispose();
    audio.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    // Clear "justPressed/justReleased" states from previous frame
    input.beginFrame();

    final currentTime = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final dt = currentTime - _lastTime;
    _lastTime = currentTime;
    tickerCount++;
    _frameCount++;

    // Calculate FPS every second
    if (currentTime - _fpsLastMeasureTime >= 1.0) {
      fps = _frameCount / (currentTime - _fpsLastMeasureTime);
      _frameCount = 0;
      _fpsLastMeasureTime = currentTime;
    }

    // Process the SceneTree (lifecycle updates)
    tree.process(dt);

    physicsWorld?.update(dt);
    sceneManager.update(dt);
    tweenManager.update(dt);

    // Use first visible registered camera (O(1) instead of O(n) tree traversal)
    activeCamera = _activeCameras.firstWhere(
      (cam) => cam.visible,
      orElse: () {
        _defaultCamera ??= FCameraNode(name: 'DefaultCamera');
        return _defaultCamera!;
      },
    );

    // Update Audio Listener
    audio.updateListener(activeCamera!);

    _prepareRender();

    notifyListeners();

    if (onUpdate != null) {
      onUpdate!();
    }
  }

  void _prepareRender() {
    renderNodes.clear();
    lights.clear();
    emitters.clear();
    _collectNodes(scene);
  }

  void _collectNodes(FNode node) {
    if (node != scene) {
      if (!node.visible) return; // Basic visibility culling at collection time

      if (node is FLightNode) {
        lights.add(node);
      } else if (node is FParticleEmitter) {
        emitters.add(node);
      } else {
        renderNodes.add(node);
      }
    }
    for (final child in node.children) {
      _collectNodes(child);
    }
  }
}
