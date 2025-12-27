import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';
import '../math/transform.dart';
import '../rendering/light.dart';
import 'tree.dart';

enum ProcessMode { inherit, always, paused, disabled }

class FNode {
  String name;
  final FTransform transform = FTransform();
  FNode? parent;
  final List<FNode> children = [];
  bool visible = true;
  bool billboard = false;

  // -- Lifecycle --
  FSceneTree? _tree;
  FSceneTree? get tree => _tree;
  bool get isInsideTree => _tree != null;

  ProcessMode processMode = ProcessMode.inherit;

  /// Current lighting for this node (available during draw)
  List<FLightNode> _currentLights = [];
  List<FLightNode> get lights => _currentLights;

  bool _worldDirty = true;
  final Matrix4 _cachedWorldMatrix = Matrix4.identity();
  Vector3? _cachedWorldPosition;

  /// AABB for Frustum Culling. If null, node is always drawn.
  /// Subclasses should override this for performance.
  Rect? get bounds => null;

  FNode({this.name = 'FNode'}) {
    transform.onChanged = setWorldDirty;
  }

  // -- Lifecycle Virtual Methods (Godot Style) --

  /// Called when the node enters the SceneTree.
  void enterTree() {}

  /// Called when the node is "ready", i.e. when all children have entered the tree.
  void ready() {}

  /// Called when the node is about to exit the SceneTree.
  void exitTree() {}

  /// Called every frame if processing is enabled.
  void process(double dt) {}

  // -- Internal Lifecycle --

  /// Internal: Propagates enterTree notification
  void propagateEnterTree(FSceneTree gameTree) {
    if (_tree != null) return; // Already in tree
    _tree = gameTree;

    enterTree();

    for (final child in children) {
      child.propagateEnterTree(gameTree);
    }

    // Ready is called post-order (children first, then parent)
    // BUT Godot calls _enter_tree pre-order and _ready post-order.
    // For simplicity locally, separate pass or simple queue?
    // In Godot: enter_tree (top-down), ready (bottom-up).

    // We can do ready here if we want immediate synchronous,
    // but better to let the tree orchestrate "ready" callback if possible,
    // or just do it recursively here for now.
    propagateReady();
  }

  void propagateReady() {
    // Children are already processed via propagateEnterTree recursion which calls ready()
    // strictly speaking Godot does post-order ready.
    // Our propagateEnterTree does: 1. set tree 2. enterTree 3. recurse children 4. ready
    // So ready() is called after children are entered.

    // logic is in propagateEnterTree, so this method might be redundant or just a hook.
    // For now, keep it empty or remove loop.
    ready();
  }

  void propagateExitTree() {
    if (_tree == null) return;

    exitTree();

    for (final child in children) {
      child.propagateExitTree();
    }
    _tree = null;
  }

  void dispose() {
    for (final child in children) {
      child.dispose();
    }
  }

  void addChild(FNode child) {
    if (child.parent != null) {
      child.parent!.removeChild(child);
    }
    child.parent = this;
    children.add(child);
    child.setWorldDirty();

    if (isInsideTree) {
      child.propagateEnterTree(_tree!);
    }
  }

  void removeChild(FNode child) {
    if (children.remove(child)) {
      if (child.isInsideTree) {
        child.propagateExitTree();
      }
      child.parent = null;
      child.setWorldDirty();
    }
  }

  /// Mark this node and all its descendants as dirty
  void setWorldDirty() {
    if (_worldDirty) return;
    _worldDirty = true;
    _cachedWorldPosition = null;
    for (final child in children) {
      child.setWorldDirty();
    }
  }

  void queueFree() {
    if (parent != null) {
      parent!.removeChild(this);
    }
  }

  void update(double dt) {
    if (!_canProcess()) return;

    process(dt);

    for (final child in children) {
      child.update(dt);
    }
  }

  bool _canProcess() {
    if (processMode == ProcessMode.disabled) return false;
    if (processMode == ProcessMode.always) return true;
    if (processMode == ProcessMode.inherit) {
      if (parent != null) return parent!._canProcess();
      return true; // Root defaults to true
    }

    // Manage Paused state via Tree (TODO)
    // if (tree?.paused == true && processMode == ProcessMode.paused) ...
    return true;
  }

  void render(Canvas canvas, Matrix4 globalTransform) {
    if (!visible) return;

    final worldM = worldMatrix;

    canvas.save();
    canvas.transform(worldM.storage);
    draw(canvas);
    canvas.restore();

    for (final child in children) {
      child.render(canvas, worldM);
    }
  }

  /// Render only this node using its pre-calculated world matrix
  void renderSelf(Canvas canvas, Matrix4 viewportProjectionMatrix, List<FLightNode> activeLights) {
    if (!visible) return;

    // Frustum Culling check
    if (bounds != null) {
      // Very basic culling: Check if world position Z is behind camera is done in loop usually
      // Ideally we project bounds to screen and check intersection with viewport
      // For now, let's just skip if bounds are completely off-screen in simple 2D terms if needed
      // But we are in 3D, so we rely on standard pipeline for now.
      // Optimization: Subclasses with bounds will enable future spatial partitioning
    }

    _currentLights = activeLights;

    Matrix4 renderMatrix;
    if (billboard) {
      final worldPos = worldMatrix.getTranslation();
      final scaleX = Vector3(worldMatrix.storage[0], worldMatrix.storage[1], worldMatrix.storage[2]).length;
      final scaleY = Vector3(worldMatrix.storage[4], worldMatrix.storage[5], worldMatrix.storage[6]).length;
      final scaleZ = Vector3(worldMatrix.storage[8], worldMatrix.storage[9], worldMatrix.storage[10]).length;
      final avgScale = (scaleX + scaleY + scaleZ) / 3.0;

      renderMatrix = viewportProjectionMatrix.clone()
        ..translate(worldPos.x, worldPos.y, worldPos.z)
        ..scale(avgScale, avgScale, avgScale);
    } else {
      renderMatrix = viewportProjectionMatrix * worldMatrix;
    }

    canvas.save();
    canvas.transform(renderMatrix.storage);
    draw(canvas);
    canvas.restore();
  }

  /// Override this to draw the node's content.
  /// You can access [lights] to implement lighting effects.
  void draw(Canvas canvas) {}

  /// Calculate world position
  Vector3 get worldPosition {
    _cachedWorldPosition ??= worldMatrix.getTranslation();
    return _cachedWorldPosition!;
  }

  Matrix4 get worldMatrix {
    if (_worldDirty || transform.isDirty) {
      if (parent == null || parent is! FNode) {
        _cachedWorldMatrix.setFrom(transform.matrix);
      } else {
        _cachedWorldMatrix.setFrom((parent as FNode).worldMatrix * transform.matrix);
      }
      _worldDirty = false;
    }
    return _cachedWorldMatrix;
  }
}
