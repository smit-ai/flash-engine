import 'dart:ui';
import 'f_grid.dart';

/// Diagonal movement mode for square grids.
enum DiagonalMode {
  /// No diagonal movement allowed (4-directional)
  never,

  /// Always allow diagonal movement (8-directional)
  always,

  /// Allow diagonal only if at least one adjacent cell is walkable
  ifOneWalkable,

  /// Allow diagonal only if both adjacent cells are walkable
  ifBothWalkable,
}

/// A standard square/rectangular grid.
///
/// This is the most common grid type, used in games like:
/// - Chess, Checkers
/// - Tetris, Match-3
/// - Top-down RPGs (Pokemon, Zelda)
/// - Roguelikes
class FSquareGrid extends FGrid {
  /// How diagonal movement is handled
  final DiagonalMode diagonalMode;

  const FSquareGrid({required super.cellWidth, super.cellHeight, this.diagonalMode = DiagonalMode.always});

  @override
  Offset gridToLocal(int x, int y) {
    return Offset(x * cellWidth, y * cellHeight);
  }

  @override
  ({int x, int y}) localToGrid(double x, double y) {
    return (x: (x / cellWidth).floor(), y: (y / cellHeight).floor());
  }

  @override
  List<({int x, int y})> getNeighbors(int x, int y) {
    final neighbors = <({int x, int y})>[];

    // Cardinal directions (always included)
    neighbors.add((x: x + 1, y: y)); // Right
    neighbors.add((x: x - 1, y: y)); // Left
    neighbors.add((x: x, y: y + 1)); // Down
    neighbors.add((x: x, y: y - 1)); // Up

    // Diagonal directions (based on mode)
    if (diagonalMode != DiagonalMode.never) {
      neighbors.add((x: x + 1, y: y - 1)); // Top-Right
      neighbors.add((x: x - 1, y: y - 1)); // Top-Left
      neighbors.add((x: x + 1, y: y + 1)); // Bottom-Right
      neighbors.add((x: x - 1, y: y + 1)); // Bottom-Left
    }

    return neighbors;
  }

  @override
  double distance(int x1, int y1, int x2, int y2) {
    final dx = (x2 - x1).abs();
    final dy = (y2 - y1).abs();

    if (diagonalMode == DiagonalMode.never) {
      // Manhattan distance for 4-directional
      return (dx + dy).toDouble();
    } else {
      // Chebyshev distance for 8-directional (diagonal costs 1)
      return dx > dy ? dx.toDouble() : dy.toDouble();
    }
  }

  /// Get cardinal neighbors only (4-directional).
  List<({int x, int y})> getCardinalNeighbors(int x, int y) {
    return [(x: x + 1, y: y), (x: x - 1, y: y), (x: x, y: y + 1), (x: x, y: y - 1)];
  }

  /// Get diagonal neighbors only.
  List<({int x, int y})> getDiagonalNeighbors(int x, int y) {
    return [(x: x + 1, y: y - 1), (x: x - 1, y: y - 1), (x: x + 1, y: y + 1), (x: x - 1, y: y + 1)];
  }
}
