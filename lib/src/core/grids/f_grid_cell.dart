/// Data structure representing a single cell in a grid.
///
/// Stores properties like walkability, movement cost, and custom data
/// for pathfinding and game logic.
class FGridCell<T> {
  /// Grid X coordinate
  final int x;

  /// Grid Y coordinate
  final int y;

  /// Whether this cell can be traversed
  bool walkable;

  /// Movement cost modifier (1.0 = normal, 2.0 = double cost, etc.)
  double weight;

  /// Custom data attached to this cell (tile type, entity, etc.)
  T? data;

  FGridCell({required this.x, required this.y, this.walkable = true, this.weight = 1.0, this.data});

  /// Unique key for this cell (useful for Map storage)
  String get key => '$x,$y';

  /// Create a copy with optional overrides
  FGridCell<T> copyWith({bool? walkable, double? weight, T? data}) {
    return FGridCell<T>(
      x: x,
      y: y,
      walkable: walkable ?? this.walkable,
      weight: weight ?? this.weight,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FGridCell && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ (y.hashCode << 16);

  @override
  String toString() => 'FGridCell($x, $y, walkable: $walkable, weight: $weight)';
}

/// A sparse grid data structure for storing cells.
///
/// Uses a Map internally, so only occupied cells consume memory.
/// Ideal for infinite or very large grids.
class FGridData<T> {
  final Map<String, FGridCell<T>> _cells = {};

  /// Get a cell, returns null if not set
  FGridCell<T>? getCell(int x, int y) {
    return _cells['$x,$y'];
  }

  /// Set or create a cell
  void setCell(FGridCell<T> cell) {
    _cells[cell.key] = cell;
  }

  /// Remove a cell
  void removeCell(int x, int y) {
    _cells.remove('$x,$y');
  }

  /// Check if a cell exists
  bool hasCell(int x, int y) {
    return _cells.containsKey('$x,$y');
  }

  /// Check if a cell is walkable (returns true if not set)
  bool isWalkable(int x, int y) {
    final cell = getCell(x, y);
    return cell?.walkable ?? true;
  }

  /// Get weight of a cell (returns 1.0 if not set)
  double getWeight(int x, int y) {
    final cell = getCell(x, y);
    return cell?.weight ?? 1.0;
  }

  /// Set walkability of a cell
  void setWalkable(int x, int y, bool walkable) {
    final existing = getCell(x, y);
    if (existing != null) {
      existing.walkable = walkable;
    } else {
      setCell(FGridCell(x: x, y: y, walkable: walkable));
    }
  }

  /// Get all cells
  Iterable<FGridCell<T>> get cells => _cells.values;

  /// Number of stored cells
  int get length => _cells.length;

  /// Clear all cells
  void clear() => _cells.clear();
}
