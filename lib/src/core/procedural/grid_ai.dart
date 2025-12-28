import 'dart:math' as math;

/// Abstract base for grid-based AI agents.
///
/// Grid agents move on discrete tile positions and update
/// based on player position and time.
abstract class FGridAgent {
  int x;
  int y;

  /// Movement cooldown in milliseconds
  final int moveCooldownMs;
  int _lastMoveTime = 0;

  FGridAgent({required this.x, required this.y, this.moveCooldownMs = 500});

  /// Update agent (call each frame)
  void update(int playerX, int playerY, int currentTimeMs) {
    if (currentTimeMs - _lastMoveTime < moveCooldownMs) return;
    _lastMoveTime = currentTimeMs;
    move(playerX, playerY);
  }

  /// Override to implement movement logic
  void move(int playerX, int playerY);

  /// Distance to player (Manhattan)
  int distanceTo(int px, int py) => (x - px).abs() + (y - py).abs();

  /// Unique key for this agent position
  String get key => '$x,$y';
}

/// Patrol agent - follows a fixed path
class FPatrolAgent extends FGridAgent {
  final List<({int x, int y})> path;
  int _pathIndex = 0;
  bool _forward = true;

  FPatrolAgent({required super.x, required super.y, required this.path, super.moveCooldownMs = 800});

  @override
  void move(int playerX, int playerY) {
    if (path.isEmpty) return;

    final target = path[_pathIndex];
    x = target.x;
    y = target.y;

    if (_forward) {
      _pathIndex++;
      if (_pathIndex >= path.length) {
        _pathIndex = path.length - 2;
        _forward = false;
      }
    } else {
      _pathIndex--;
      if (_pathIndex < 0) {
        _pathIndex = 1;
        _forward = true;
      }
    }
  }

  /// Create a rectangular patrol path
  static FPatrolAgent rectangle(int startX, int startY, int width, int height) {
    final path = <({int x, int y})>[];
    // Top edge
    for (int i = 0; i < width; i++) {
      path.add((x: startX + i, y: startY));
    }
    // Right edge
    for (int i = 1; i < height; i++) {
      path.add((x: startX + width - 1, y: startY + i));
    }
    // Bottom edge
    for (int i = width - 2; i >= 0; i--) {
      path.add((x: startX + i, y: startY + height - 1));
    }
    // Left edge
    for (int i = height - 2; i > 0; i--) {
      path.add((x: startX, y: startY + i));
    }
    return FPatrolAgent(x: startX, y: startY, path: path);
  }
}

/// Chaser agent - follows player when within range
class FChaserAgent extends FGridAgent {
  /// Detection range (Manhattan distance)
  final int detectionRange;

  FChaserAgent({required super.x, required super.y, this.detectionRange = 5, super.moveCooldownMs = 600});

  @override
  void move(int playerX, int playerY) {
    final distance = distanceTo(playerX, playerY);
    if (distance > detectionRange) return;

    final dx = playerX - x;
    final dy = playerY - y;

    // Move towards player (prioritize larger axis)
    if (dx.abs() > dy.abs()) {
      x += dx.sign;
    } else if (dy != 0) {
      y += dy.sign;
    }
  }
}

/// Wanderer agent - moves randomly
class FWandererAgent extends FGridAgent {
  final math.Random _random;

  /// Maximum distance from spawn point
  final int wanderRadius;
  final int _spawnX;
  final int _spawnY;

  FWandererAgent({required super.x, required super.y, this.wanderRadius = 5, int? seed, super.moveCooldownMs = 1000})
    : _spawnX = x,
      _spawnY = y,
      _random = math.Random(seed);

  @override
  void move(int playerX, int playerY) {
    final direction = _random.nextInt(5); // 0-3: move, 4: stay

    int newX = x;
    int newY = y;

    switch (direction) {
      case 0:
        newX++;
        break;
      case 1:
        newX--;
        break;
      case 2:
        newY++;
        break;
      case 3:
        newY--;
        break;
    }

    // Check wander radius
    if ((newX - _spawnX).abs() <= wanderRadius && (newY - _spawnY).abs() <= wanderRadius) {
      x = newX;
      y = newY;
    }
  }
}

/// Jumper agent - teleports randomly
class FJumperAgent extends FGridAgent {
  final int jumpDistance;
  final math.Random _random;

  FJumperAgent({required super.x, required super.y, this.jumpDistance = 2, int? seed, super.moveCooldownMs = 1200})
    : _random = math.Random(seed);

  @override
  void move(int playerX, int playerY) {
    final direction = _random.nextInt(4);

    switch (direction) {
      case 0:
        x += jumpDistance;
        break;
      case 1:
        x -= jumpDistance;
        break;
      case 2:
        y += jumpDistance;
        break;
      case 3:
        y -= jumpDistance;
        break;
    }
  }
}

/// Fleeing agent - runs away from player
class FFleeAgent extends FGridAgent {
  final int fleeRange;

  FFleeAgent({required super.x, required super.y, this.fleeRange = 4, super.moveCooldownMs = 400});

  @override
  void move(int playerX, int playerY) {
    final distance = distanceTo(playerX, playerY);
    if (distance > fleeRange) return;

    final dx = x - playerX;
    final dy = y - playerY;

    // Move away from player
    if (dx.abs() > dy.abs()) {
      x += dx.sign;
    } else if (dy != 0) {
      y += dy.sign;
    }
  }
}
