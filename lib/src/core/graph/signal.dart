/// A signal that allows listeners to subscribe to events.
/// Modeled after Godot's Signal system but type-safe for Dart.
class FSignal<T> {
  final List<void Function(T payload)> _listeners = [];

  void connect(void Function(T payload) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void disconnect(void Function(T payload) listener) {
    _listeners.remove(listener);
  }

  void emit(T payload) {
    for (final listener in List.of(_listeners)) {
      listener(payload);
    }
  }
}

/// Helper for signals with no payload
class FSignalVoid {
  final List<VoidCallback> _listeners = [];

  void connect(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void disconnect(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void emit() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

typedef VoidCallback = void Function();
