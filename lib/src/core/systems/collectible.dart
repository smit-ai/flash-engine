import 'package:flutter/foundation.dart';

/// Types of collectible items.
enum FCollectibleType {
  /// Standard points item
  points,

  /// Health/life restore
  health,

  /// Currency/coin
  currency,

  /// Key for unlocking
  key,

  /// Temporary power-up
  powerUp,

  /// Special/rare item
  special,
}

/// A collectible item definition.
class FCollectibleDef {
  /// Item type
  final FCollectibleType type;

  /// Point value when collected
  final int points;

  /// Custom data (power-up duration, etc.)
  final Map<String, dynamic>? data;

  const FCollectibleDef({required this.type, this.points = 0, this.data});
}

/// Collectible system with type registration and collection tracking.
///
/// Example:
/// ```dart
/// final collectibles = FCollectibleSystem();
/// collectibles.register('diamond', FCollectibleDef(type: FCollectibleType.points, points: 10));
/// collectibles.register('star', FCollectibleDef(type: FCollectibleType.points, points: 25));
///
/// // On collection:
/// final item = collectibles.collect('diamond', 5, 3);
/// if (item != null) {
///   score += item.points;
/// }
/// ```
class FCollectibleSystem extends ChangeNotifier {
  /// Registered collectible types
  final Map<String, FCollectibleDef> _definitions = {};

  /// Collected item positions (name -> set of "x,y" keys)
  final Map<String, Set<String>> _collected = {};

  /// Total items collected per type
  final Map<String, int> _counts = {};

  /// Register a collectible type
  void register(String name, FCollectibleDef def) {
    _definitions[name] = def;
    _counts[name] = 0;
  }

  /// Get definition for a type
  FCollectibleDef? getDef(String name) => _definitions[name];

  /// Check if position has uncollected item
  bool hasItem(String name, int x, int y) {
    final key = '$x,$y';
    return !(_collected[name]?.contains(key) ?? false);
  }

  /// Collect item at position
  FCollectibleDef? collect(String name, int x, int y) {
    final def = _definitions[name];
    if (def == null) return null;

    final key = '$x,$y';
    if (_collected[name]?.contains(key) ?? false) return null;

    _collected.putIfAbsent(name, () => {}).add(key);
    _counts[name] = (_counts[name] ?? 0) + 1;
    notifyListeners();

    return def;
  }

  /// Get count of collected items of type
  int getCount(String name) => _counts[name] ?? 0;

  /// Get total collected across all types
  int get totalCollected => _counts.values.fold(0, (a, b) => a + b);

  /// Check if item was collected at position
  bool isCollected(String name, int x, int y) {
    final key = '$x,$y';
    return _collected[name]?.contains(key) ?? false;
  }

  /// Reset all collections
  void reset() {
    _collected.clear();
    _counts.updateAll((key, value) => 0);
    notifyListeners();
  }

  /// Get all collected positions for a type
  Set<String> getCollectedPositions(String name) => _collected[name] ?? {};
}

/// Power-up definition
class FPowerUpDef {
  /// Unique identifier
  final String id;

  /// Display name
  final String name;

  /// Duration of effect
  final Duration duration;

  /// Effect intensity/value
  final double value;

  const FPowerUpDef({required this.id, required this.name, required this.duration, this.value = 1.0});
}

/// Active power-up tracker.
class FPowerUpSystem extends ChangeNotifier {
  /// Registered power-up types
  final Map<String, FPowerUpDef> _definitions = {};

  /// Active power-ups with expiration time
  final Map<String, DateTime> _active = {};

  /// Register power-up type
  void register(FPowerUpDef def) {
    _definitions[def.id] = def;
  }

  /// Activate a power-up
  void activate(String id) {
    final def = _definitions[id];
    if (def == null) return;

    _active[id] = DateTime.now().add(def.duration);
    notifyListeners();
  }

  /// Check if power-up is active
  bool isActive(String id) {
    final expiry = _active[id];
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  /// Get remaining duration
  Duration getRemaining(String id) {
    final expiry = _active[id];
    if (expiry == null) return Duration.zero;
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get power-up value (if active)
  double? getValue(String id) {
    if (!isActive(id)) return null;
    return _definitions[id]?.value;
  }

  /// Update and clean expired power-ups
  void update() {
    final now = DateTime.now();
    _active.removeWhere((id, expiry) => now.isAfter(expiry));
    notifyListeners();
  }

  /// Deactivate specific power-up
  void deactivate(String id) {
    _active.remove(id);
    notifyListeners();
  }

  /// Get all active power-up IDs
  List<String> get activeIds => _active.keys.where((id) => isActive(id)).toList();

  /// Reset all power-ups
  void reset() {
    _active.clear();
    notifyListeners();
  }
}
