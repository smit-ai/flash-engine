import 'node.dart';

/// Manages the game loop, root node, and global state.
/// This mirrors Godot's SceneTree.
class FSceneTree {
  /// The absolute root of the scene tree.
  late final FNode root;

  /// The currently active scene (usually a child of root).
  FNode? currentScene;

  bool paused = false;

  /// Global group management (Node path -> Nodes) - Placeholder for Phase 3
  // final Map<String, List<FlashNode>> _groups = {};

  FSceneTree() {
    root = FNode(name: 'root');
    // Root is technically always "in the tree"
    root.processMode = ProcessMode.always;
    _initializeRoot();
  }

  void _initializeRoot() {
    // Manually trigger enterTree for root since it has no parent to propagate it
    root.propagateEnterTree(this);
  }

  /// Change the current scene.
  /// This removes the old scene and adds the new one to root.
  void changeScene(FNode newScene) {
    if (currentScene != null) {
      currentScene!.queueFree();
      // For now, manual remove
      root.removeChild(currentScene!);
    }
    currentScene = newScene;
    root.addChild(currentScene!);
  }

  /// Main process loop.
  void process(double dt) {
    if (paused) return; // Or handle Paused process mode
    root.update(dt);
  }
}
