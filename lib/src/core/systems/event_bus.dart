import 'dart:async';
import 'package:flutter/widgets.dart';

/// Base class for all events
abstract class FEvent {
  final DateTime timestamp = DateTime.now();

  /// Event name for debugging
  String get name => runtimeType.toString();
}

/// Typed event with payload
class FDataEvent<T> extends FEvent {
  final T data;

  FDataEvent(this.data);

  @override
  String get name => 'FDataEvent<${T.runtimeType}>($data)';
}

/// Simple string event
class FSignalEvent extends FEvent {
  final String signal;

  FSignalEvent(this.signal);

  @override
  String get name => signal;
}

/// Event subscription holder
class _Subscription<T extends FEvent> {
  final void Function(T event) handler;
  final bool once;
  bool cancelled = false;

  _Subscription(this.handler, {this.once = false});

  void call(T event) {
    if (!cancelled) handler(event);
  }

  void cancel() => cancelled = true;
}

/// Subscription handle for unsubscribing
class FEventSubscription {
  final VoidCallback _unsubscribe;

  FEventSubscription(this._unsubscribe);

  void cancel() => _unsubscribe();
}

/// Global event bus for game-wide communication
class FEventBus {
  static final FEventBus _instance = FEventBus._internal();
  static FEventBus get instance => _instance;

  factory FEventBus() => _instance;

  FEventBus._internal();

  final Map<Type, List<_Subscription>> _handlers = {};
  final List<FEvent> _eventHistory = [];
  final int maxHistorySize = 50;

  /// Stream controller for reactive listening
  final StreamController<FEvent> _streamController = StreamController.broadcast();

  /// Stream of all events
  Stream<FEvent> get stream => _streamController.stream;

  /// Event history
  List<FEvent> get history => List.unmodifiable(_eventHistory);

  /// Subscribe to events of a specific type
  FEventSubscription on<T extends FEvent>(void Function(T event) handler) {
    _handlers.putIfAbsent(T, () => []);
    final sub = _Subscription<T>(handler);
    _handlers[T]!.add(sub);

    return FEventSubscription(() {
      sub.cancel();
      _handlers[T]?.remove(sub);
    });
  }

  /// Subscribe to an event type, but only fire once
  FEventSubscription once<T extends FEvent>(void Function(T event) handler) {
    late FEventSubscription subscription;
    subscription = on<T>((event) {
      handler(event);
      subscription.cancel();
    });
    return subscription;
  }

  /// Emit an event to all subscribers
  void emit<T extends FEvent>(T event) {
    // Add to history
    _eventHistory.add(event);
    if (_eventHistory.length > 50) {
      _eventHistory.removeAt(0);
    }

    // Notify stream listeners
    _streamController.add(event);

    // Notify type-specific handlers
    final handlers = _handlers[T];
    if (handlers != null) {
      // Create copy to avoid modification during iteration
      for (final handler in List.from(handlers)) {
        if (!handler.cancelled) {
          (handler as _Subscription<T>).call(event);
        }
      }
      // Clean up cancelled handlers
      handlers.removeWhere((h) => h.cancelled);
    }

    // Also notify handlers for parent types (FEvent catches all)
    if (T != FEvent) {
      final baseHandlers = _handlers[FEvent];
      if (baseHandlers != null) {
        for (final handler in List.from(baseHandlers)) {
          if (!handler.cancelled) {
            (handler as _Subscription<FEvent>).call(event);
          }
        }
      }
    }
  }

  /// Emit a simple signal
  void signal(String name) => emit(FSignalEvent(name));

  /// Emit a data event
  void data<T>(T payload) => emit(FDataEvent<T>(payload));

  /// Clear all handlers
  void clear() {
    _handlers.clear();
    _eventHistory.clear();
  }

  /// Remove all handlers for a specific type
  void clearType<T extends FEvent>() {
    _handlers.remove(T);
  }

  void dispose() {
    clear();
    _streamController.close();
  }
}

/// Widget that listens to events and rebuilds
class FEventListener<T extends FEvent> extends StatefulWidget {
  final Widget Function(BuildContext context, T? lastEvent) builder;
  final void Function(T event)? onEvent;

  const FEventListener({super.key, required this.builder, this.onEvent});

  @override
  State<FEventListener<T>> createState() => _FEventListenerState<T>();
}

class _FEventListenerState<T extends FEvent> extends State<FEventListener<T>> {
  FEventSubscription? _subscription;
  T? _lastEvent;

  @override
  void initState() {
    super.initState();
    _subscription = FEventBus.instance.on<T>((event) {
      widget.onEvent?.call(event);
      if (mounted) setState(() => _lastEvent = event);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _lastEvent);
}

/// Mixin for widgets that need to subscribe to events
mixin FEventMixin<T extends StatefulWidget> on State<T> {
  final List<FEventSubscription> _subscriptions = [];

  /// Subscribe to an event type
  void subscribe<E extends FEvent>(void Function(E event) handler) {
    _subscriptions.add(FEventBus.instance.on<E>(handler));
  }

  /// Emit an event
  void emit<E extends FEvent>(E event) {
    FEventBus.instance.emit(event);
  }

  /// Emit a signal
  void signal(String name) {
    FEventBus.instance.signal(name);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

// --- Common Game Events ---

/// Player took damage
class PlayerDamageEvent extends FEvent {
  final int damage;
  final int remainingHealth;

  PlayerDamageEvent(this.damage, this.remainingHealth);
}

/// Player died
class PlayerDeathEvent extends FEvent {}

/// Score changed
class ScoreChangedEvent extends FEvent {
  final int oldScore;
  final int newScore;

  ScoreChangedEvent(this.oldScore, this.newScore);

  int get delta => newScore - oldScore;
}

/// Level completed
class LevelCompleteEvent extends FEvent {
  final int level;
  final int stars;

  LevelCompleteEvent(this.level, this.stars);
}

/// Game paused/resumed
class GamePauseEvent extends FEvent {
  final bool paused;

  GamePauseEvent(this.paused);
}

/// Collectible collected
class CollectEvent extends FEvent {
  final String itemType;
  final int value;

  CollectEvent(this.itemType, this.value);
}
