import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

/// Represents the state of an input action
enum InputState {
  /// Not pressed
  released,

  /// Just pressed this frame
  justPressed,

  /// Being held down
  held,

  /// Just released this frame
  justReleased,
}

/// Direction of a swipe gesture
enum SwipeDirection { up, down, left, right }

/// Defines an input action that can be mapped to keys/buttons
class FlashInputAction {
  final String name;
  final Set<LogicalKeyboardKey> keys;
  final Set<int> mouseButtons; // 0 = left, 1 = middle, 2 = right

  const FlashInputAction({required this.name, this.keys = const {}, this.mouseButtons = const {}});

  /// Common preset actions
  static final moveUp = FlashInputAction(name: 'move_up', keys: {LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp});

  static final moveDown = FlashInputAction(
    name: 'move_down',
    keys: {LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown},
  );

  static final moveLeft = FlashInputAction(
    name: 'move_left',
    keys: {LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft},
  );

  static final moveRight = FlashInputAction(
    name: 'move_right',
    keys: {LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight},
  );

  static final jump = FlashInputAction(name: 'jump', keys: {LogicalKeyboardKey.space});

  static final attack = FlashInputAction(
    name: 'attack',
    keys: {LogicalKeyboardKey.keyZ},
    mouseButtons: {0}, // Left click
  );

  static final interact = FlashInputAction(name: 'interact', keys: {LogicalKeyboardKey.keyE, LogicalKeyboardKey.enter});

  static final pause = FlashInputAction(name: 'pause', keys: {LogicalKeyboardKey.escape});
}

/// Core input system that tracks keyboard and pointer state
class FlashInputSystem {
  // Keyboard state
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final Set<LogicalKeyboardKey> _justPressedKeys = {};
  final Set<LogicalKeyboardKey> _justReleasedKeys = {};

  // Mouse/Pointer state
  final Set<int> _pressedMouseButtons = {};
  final Set<int> _justPressedMouseButtons = {};
  final Set<int> _justReleasedMouseButtons = {};

  // Pointer position (screen coordinates)
  Offset _pointerPosition = Offset.zero;
  Offset _pointerDelta = Offset.zero;
  Offset _lastPointerPosition = Offset.zero;

  // Action mappings
  final Map<String, FlashInputAction> _actions = {};

  // Scroll
  double _scrollDelta = 0.0;

  // ============ Multi-Touch / Gesture State ============

  // Active touch points (pointer ID -> position)
  final Map<int, Offset> _activePointers = {};

  // Gesture detection
  double _pinchScale = 1.0;
  double _pinchScaleDelta = 0.0;
  double _initialPinchDistance = 0.0;
  bool _isPinching = false;

  // Swipe detection
  Offset _swipeStartPosition = Offset.zero;
  DateTime _swipeStartTime = DateTime.now();
  SwipeDirection? _detectedSwipe;
  static const double _swipeThreshold = 50.0; // minimum pixels
  static const Duration _swipeMaxDuration = Duration(milliseconds: 300);

  // Long press detection
  DateTime? _longPressStartTime;
  bool _longPressTriggered = false;
  static const Duration _longPressDuration = Duration(milliseconds: 500);

  // Double tap detection
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  bool _doubleTapDetected = false;
  static const Duration _doubleTapMaxInterval = Duration(milliseconds: 300);
  static const double _doubleTapMaxDistance = 30.0;

  // ============ Gesture Getters ============

  /// Number of active touch points
  int get touchCount => _activePointers.length;

  /// Whether currently pinching (two fingers)
  bool get isPinching => _isPinching;

  /// Current pinch scale (1.0 = no scale, >1 = zoom in, <1 = zoom out)
  double get pinchScale => _pinchScale;

  /// Change in pinch scale since last frame
  double get pinchScaleDelta => _pinchScaleDelta;

  /// Detected swipe direction this frame (null if none)
  SwipeDirection? get swipeDirection => _detectedSwipe;

  /// Whether a long press was triggered this frame
  bool get isLongPressTriggered => _longPressTriggered;

  /// Whether a double tap was detected this frame
  bool get isDoubleTap => _doubleTapDetected;

  /// Get position of specific touch point (null if not active)
  Offset? getTouchPosition(int index) {
    if (index < _activePointers.length) {
      return _activePointers.values.elementAt(index);
    }
    return null;
  }

  /// Get center point between all active touches
  Offset get touchCenter {
    if (_activePointers.isEmpty) return Offset.zero;
    final sum = _activePointers.values.reduce((a, b) => a + b);
    return sum / _activePointers.length.toDouble();
  }

  /// Current pointer position in screen coordinates
  Offset get pointerPosition => _pointerPosition;

  /// Pointer movement delta since last update
  Offset get pointerDelta => _pointerDelta;

  /// Scroll wheel delta (positive = up, negative = down)
  double get scrollDelta => _scrollDelta;

  /// Register an action for easy querying
  void registerAction(FlashInputAction action) {
    _actions[action.name] = action;
  }

  /// Register multiple actions at once
  void registerActions(List<FlashInputAction> actions) {
    for (final action in actions) {
      registerAction(action);
    }
  }

  /// Unregister an action
  void unregisterAction(String name) {
    _actions.remove(name);
  }

  /// Clear all registered actions
  void clearActions() {
    _actions.clear();
  }

  // ============ Keyboard Methods ============

  /// Check if a specific key is currently pressed
  bool isKeyPressed(LogicalKeyboardKey key) => _pressedKeys.contains(key);

  /// Check if a key was just pressed this frame
  bool isKeyJustPressed(LogicalKeyboardKey key) => _justPressedKeys.contains(key);

  /// Check if a key was just released this frame
  bool isKeyJustReleased(LogicalKeyboardKey key) => _justReleasedKeys.contains(key);

  /// Check if any of the given keys are pressed
  bool isAnyKeyPressed(Set<LogicalKeyboardKey> keys) {
    return keys.any((key) => _pressedKeys.contains(key));
  }

  /// Check if all of the given keys are pressed (combo)
  bool areAllKeysPressed(Set<LogicalKeyboardKey> keys) {
    return keys.every((key) => _pressedKeys.contains(key));
  }

  // ============ Mouse Methods ============

  /// Check if a mouse button is pressed (0=left, 1=middle, 2=right)
  bool isMouseButtonPressed(int button) => _pressedMouseButtons.contains(button);

  /// Check if a mouse button was just pressed
  bool isMouseButtonJustPressed(int button) => _justPressedMouseButtons.contains(button);

  /// Check if a mouse button was just released
  bool isMouseButtonJustReleased(int button) => _justReleasedMouseButtons.contains(button);

  /// Convenience getters
  bool get isLeftMousePressed => isMouseButtonPressed(0);
  bool get isRightMousePressed => isMouseButtonPressed(2);
  bool get isMiddleMousePressed => isMouseButtonPressed(1);

  // ============ Action Methods ============

  /// Check if an action is currently active (any mapped input is pressed)
  bool isActionPressed(String actionName) {
    final action = _actions[actionName];
    if (action == null) return false;

    // Check keyboard
    if (action.keys.any((key) => _pressedKeys.contains(key))) {
      return true;
    }

    // Check mouse buttons
    if (action.mouseButtons.any((btn) => _pressedMouseButtons.contains(btn))) {
      return true;
    }

    return false;
  }

  /// Check if an action was just pressed this frame
  bool isActionJustPressed(String actionName) {
    final action = _actions[actionName];
    if (action == null) return false;

    // Check if any key for this action was just pressed
    if (action.keys.any((key) => _justPressedKeys.contains(key))) {
      return true;
    }

    // Check mouse buttons
    if (action.mouseButtons.any((btn) => _justPressedMouseButtons.contains(btn))) {
      return true;
    }

    return false;
  }

  /// Check if an action was just released this frame
  bool isActionJustReleased(String actionName) {
    final action = _actions[actionName];
    if (action == null) return false;

    if (action.keys.any((key) => _justReleasedKeys.contains(key))) {
      return true;
    }

    if (action.mouseButtons.any((btn) => _justReleasedMouseButtons.contains(btn))) {
      return true;
    }

    return false;
  }

  /// Get movement vector based on registered movement actions
  /// Returns normalized vector (-1 to 1 on each axis)
  /// Uses SCREEN coordinates: +X = right, +Y = down
  /// For game world (Y-up), use getMovementVectorWorld()
  Offset getMovementVector() {
    double x = 0;
    double y = 0;

    if (isActionPressed('move_left') || isActionPressed(FlashInputAction.moveLeft.name)) {
      x -= 1;
    }
    if (isActionPressed('move_right') || isActionPressed(FlashInputAction.moveRight.name)) {
      x += 1;
    }
    if (isActionPressed('move_up') || isActionPressed(FlashInputAction.moveUp.name)) {
      y -= 1; // Screen: up is negative Y
    }
    if (isActionPressed('move_down') || isActionPressed(FlashInputAction.moveDown.name)) {
      y += 1;
    }

    return Offset(x, y);
  }

  /// Returns normalized vector for WORLD coordinates
  /// +X = right, +Y = UP (Flash engine / game world convention)
  Offset getMovementVectorWorld() {
    double x = 0;
    double y = 0;

    if (isActionPressed('move_left') || isActionPressed(FlashInputAction.moveLeft.name)) {
      x -= 1;
    }
    if (isActionPressed('move_right') || isActionPressed(FlashInputAction.moveRight.name)) {
      x += 1;
    }
    if (isActionPressed('move_up') || isActionPressed(FlashInputAction.moveUp.name)) {
      y += 1; // World: up is positive Y
    }
    if (isActionPressed('move_down') || isActionPressed(FlashInputAction.moveDown.name)) {
      y -= 1;
    }

    return Offset(x, y);
  }

  // ============ Internal Update Methods ============

  /// Called at the start of each frame to clear "just" states
  void beginFrame() {
    _justPressedKeys.clear();
    _justReleasedKeys.clear();
    _justPressedMouseButtons.clear();
    _justReleasedMouseButtons.clear();
    _scrollDelta = 0.0;

    _pointerDelta = _pointerPosition - _lastPointerPosition;
    _lastPointerPosition = _pointerPosition;

    // Clear per-frame gesture states
    _detectedSwipe = null;
    _doubleTapDetected = false;
    _pinchScaleDelta = 0.0;
  }

  /// Handle key down event
  void onKeyDown(LogicalKeyboardKey key) {
    if (!_pressedKeys.contains(key)) {
      _pressedKeys.add(key);
      _justPressedKeys.add(key);
    }
  }

  /// Handle key up event
  void onKeyUp(LogicalKeyboardKey key) {
    if (_pressedKeys.contains(key)) {
      _pressedKeys.remove(key);
      _justReleasedKeys.add(key);
    }
  }

  /// Handle raw key event from Flutter
  void handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      onKeyDown(key);
    } else if (event is KeyUpEvent) {
      onKeyUp(key);
    }
  }

  /// Handle pointer down (supports multi-touch)
  void onPointerDown(PointerDownEvent event) {
    final pointerId = event.pointer;
    _activePointers[pointerId] = event.position;

    // Mouse button tracking
    final button = event.buttons;
    int buttonIndex = _buttonFromFlags(button);

    if (!_pressedMouseButtons.contains(buttonIndex)) {
      _pressedMouseButtons.add(buttonIndex);
      _justPressedMouseButtons.add(buttonIndex);
    }

    _pointerPosition = event.position;

    // Start swipe tracking (single touch only)
    if (_activePointers.length == 1) {
      _swipeStartPosition = event.position;
      _swipeStartTime = DateTime.now();
    }

    // Start long press timer
    _longPressStartTime = DateTime.now();
    _longPressTriggered = false;

    // Start pinch tracking when second finger added
    if (_activePointers.length == 2) {
      _isPinching = true;
      _initialPinchDistance = _calculatePinchDistance();
      _pinchScale = 1.0;
    }
  }

  /// Handle pointer up (supports multi-touch)
  void onPointerUp(PointerUpEvent event) {
    final pointerId = event.pointer;
    final liftPosition = event.position;

    // Swipe detection (single finger lift)
    if (_activePointers.length == 1 && _activePointers.containsKey(pointerId)) {
      final elapsed = DateTime.now().difference(_swipeStartTime);
      if (elapsed <= _swipeMaxDuration) {
        final delta = liftPosition - _swipeStartPosition;
        if (delta.distance >= _swipeThreshold) {
          // Determine direction
          if (delta.dx.abs() > delta.dy.abs()) {
            _detectedSwipe = delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
          } else {
            _detectedSwipe = delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
          }
        }
      }

      // Double tap detection
      final now = DateTime.now();
      if (_lastTapTime != null && _lastTapPosition != null) {
        final tapElapsed = now.difference(_lastTapTime!);
        final tapDistance = (liftPosition - _lastTapPosition!).distance;
        if (tapElapsed <= _doubleTapMaxInterval && tapDistance <= _doubleTapMaxDistance) {
          _doubleTapDetected = true;
          _lastTapTime = null;
          _lastTapPosition = null;
        } else {
          _lastTapTime = now;
          _lastTapPosition = liftPosition;
        }
      } else {
        _lastTapTime = now;
        _lastTapPosition = liftPosition;
      }
    }

    _activePointers.remove(pointerId);

    // End pinch when less than 2 fingers
    if (_activePointers.length < 2) {
      _isPinching = false;
    }

    // Mouse button release
    for (final btn in _pressedMouseButtons.toList()) {
      _pressedMouseButtons.remove(btn);
      _justReleasedMouseButtons.add(btn);
    }
  }

  /// Handle pointer move (supports multi-touch + pinch)
  void onPointerMove(PointerMoveEvent event) {
    final pointerId = event.pointer;
    _activePointers[pointerId] = event.position;
    _pointerPosition = event.position;

    // Update pinch scale
    if (_isPinching && _activePointers.length == 2 && _initialPinchDistance > 0) {
      final currentDistance = _calculatePinchDistance();
      final newScale = currentDistance / _initialPinchDistance;
      _pinchScaleDelta = newScale - _pinchScale;
      _pinchScale = newScale;
    }

    // Check for long press
    if (_longPressStartTime != null && !_longPressTriggered) {
      final elapsed = DateTime.now().difference(_longPressStartTime!);
      if (elapsed >= _longPressDuration) {
        _longPressTriggered = true;
      }
    }
  }

  /// Handle pointer hover (no button pressed)
  void onPointerHover(PointerHoverEvent event) {
    _pointerPosition = event.position;
  }

  /// Handle scroll
  void onPointerScroll(PointerScrollEvent event) {
    _scrollDelta = -event.scrollDelta.dy; // Positive = scroll up
  }

  /// Handle pointer cancel (e.g., system gesture interrupts touch)
  void onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _isPinching = false;
    }
  }

  /// Calculate distance between two touch points
  double _calculatePinchDistance() {
    if (_activePointers.length < 2) return 0;
    final points = _activePointers.values.toList();
    return (points[0] - points[1]).distance;
  }

  /// Convert button flags to index
  int _buttonFromFlags(int buttons) {
    if (buttons & kPrimaryMouseButton != 0) return 0;
    if (buttons & kSecondaryMouseButton != 0) return 2;
    if (buttons & kMiddleMouseButton != 0) return 1;
    return 0;
  }

  /// Reset all state (useful when app loses focus)
  void reset() {
    _pressedKeys.clear();
    _justPressedKeys.clear();
    _justReleasedKeys.clear();
    _pressedMouseButtons.clear();
    _justPressedMouseButtons.clear();
    _justReleasedMouseButtons.clear();
    _scrollDelta = 0.0;
    _activePointers.clear();
    _isPinching = false;
    _pinchScale = 1.0;
    _pinchScaleDelta = 0.0;
    _detectedSwipe = null;
    _longPressTriggered = false;
    _doubleTapDetected = false;
  }
}
