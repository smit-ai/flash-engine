/// Procedural tilemap generator using deterministic hash functions.
library;

/// Procedural tilemap generator using deterministic hash functions.
///
/// Generates infinite, deterministic worlds without storing data.
/// Each tile position has a consistent, reproducible value.
///
/// Example:
/// ```dart
/// final tilemap = FProceduralTilemap(
///   seed: 42,
///   generators: {
///     'obstacle': (x, y, seed) => hashMod(x, y, seed, 73856093, 19349663, 25) == 0,
///     'diamond': (x, y, seed) => hashMod(x, y, seed, 374761393, 668265263, 100) < 8,
///   },
/// );
///
/// if (tilemap.check('obstacle', 5, 3)) { ... }
/// ```
class FProceduralTilemap {
  /// Random seed for consistent generation
  final int seed;

  /// Named tile generators
  final Map<String, bool Function(int x, int y, int seed)> _generators;

  /// Collected/removed tiles (for pickups)
  final Map<String, Set<String>> _collected = {};

  FProceduralTilemap({this.seed = 42, Map<String, bool Function(int x, int y, int seed)>? generators})
    : _generators = generators ?? {};

  /// Register a new tile generator
  void register(String name, bool Function(int x, int y, int seed) generator) {
    _generators[name] = generator;
  }

  /// Check if a tile exists at position (and not collected)
  bool check(String name, int x, int y) {
    final generator = _generators[name];
    if (generator == null) return false;

    // Check if collected
    final key = '$x,$y';
    if (_collected[name]?.contains(key) ?? false) return false;

    return generator(x, y, seed);
  }

  /// Get tile value using custom function if exists
  T? getValue<T>(String name, int x, int y, T Function(int x, int y, int seed) extractor) {
    if (!check(name, x, y)) return null;
    return extractor(x, y, seed);
  }

  /// Mark a tile as collected (won't appear again)
  void collect(String name, int x, int y) {
    _collected.putIfAbsent(name, () => {}).add('$x,$y');
  }

  /// Check if tile was collected
  bool isCollected(String name, int x, int y) {
    return _collected[name]?.contains('$x,$y') ?? false;
  }

  /// Reset all collected tiles
  void reset() {
    _collected.clear();
  }

  /// Get all tiles of a type within a region
  List<({int x, int y})> getInRegion(String name, int minX, int minY, int maxX, int maxY) {
    final tiles = <({int x, int y})>[];
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        if (check(name, x, y)) {
          tiles.add((x: x, y: y));
        }
      }
    }
    return tiles;
  }

  // ============ STATIC HASH UTILITIES ============

  /// Standard hash function with modulo
  static int hashMod(int x, int y, int seed, int primeA, int primeB, int mod) {
    int h = x * primeA ^ y * primeB ^ seed;
    h = (h ^ (h >> 13)) * 0x85ebca6b;
    h = (h ^ (h >> 16));
    return h.abs() % mod;
  }

  /// Hash to get a value in range [0, 1)
  static double hashDouble(int x, int y, int seed) {
    return hashMod(x, y, seed, 12345, 67890, 10000) / 10000.0;
  }

  /// Perlin-like noise (simplified)
  static double noise2D(double x, double y, int seed) {
    final xi = x.floor();
    final yi = y.floor();
    final xf = x - xi;
    final yf = y - yi;

    final n00 = hashDouble(xi, yi, seed);
    final n10 = hashDouble(xi + 1, yi, seed);
    final n01 = hashDouble(xi, yi + 1, seed);
    final n11 = hashDouble(xi + 1, yi + 1, seed);

    // Bilinear interpolation
    final nx0 = n00 * (1 - xf) + n10 * xf;
    final nx1 = n01 * (1 - xf) + n11 * xf;
    return nx0 * (1 - yf) + nx1 * yf;
  }

  // ============ PRESET GENERATORS ============

  /// Create an obstacle generator (clear area around origin)
  static bool Function(int, int, int) obstacleGenerator({int clearRadius = 2, int frequency = 25}) {
    return (x, y, seed) {
      if (x.abs() <= clearRadius && y.abs() <= clearRadius) return false;
      return hashMod(x, y, seed, 73856093, 19349663, frequency) == 0;
    };
  }

  /// Create a collectible generator
  static bool Function(int, int, int) collectibleGenerator({
    int frequency = 100,
    int threshold = 8,
    bool excludeOrigin = true,
  }) {
    return (x, y, seed) {
      if (excludeOrigin && x == 0 && y == 0) return false;
      return hashMod(x, y, seed, 374761393, 668265263, frequency) < threshold;
    };
  }

  /// Create a rare item generator
  static bool Function(int, int, int) rareItemGenerator({int minDistance = 3, int frequency = 200, int threshold = 2}) {
    return (x, y, seed) {
      if (x.abs() < minDistance && y.abs() < minDistance) return false;
      return hashMod(x, y, seed, 92837111, 18273645, frequency) < threshold;
    };
  }
}
