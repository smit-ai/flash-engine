import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// Demo showcasing the new Grid and Camera systems.
class GridCameraDemo extends StatefulWidget {
  const GridCameraDemo({super.key});

  @override
  State<GridCameraDemo> createState() => _GridCameraDemoState();
}

class _GridCameraDemoState extends State<GridCameraDemo> with SingleTickerProviderStateMixin {
  // Grid selection
  int _gridType = 0; // 0: Square, 1: Isometric

  // Camera
  late FGridCamera _camera;

  // Player position (grid coordinates)
  int _playerX = 0;
  int _playerY = 0;

  // Animation
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _camera = FGridCamera(zoom: 1.0, followMode: CameraFollowMode.smooth, lerpSpeed: 0.08);

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))..addListener(_update);

    _controller.repeat();
  }

  void _update() {
    // Update camera target to player position
    final grid = _getGrid();
    final playerWorld = grid.getCellCenter(_playerX, _playerY);
    _camera.target = v.Vector2(playerWorld.dx, playerWorld.dy);

    _camera.update(0.016);
    setState(() {});
  }

  FGrid _getGrid() {
    switch (_gridType) {
      case 0:
        return const FSquareGrid(cellWidth: 64.0);
      case 1:
        return const FIsometricGrid(cellWidth: 64.0);
      default:
        return const FSquareGrid(cellWidth: 64.0);
    }
  }

  void _movePlayer(int dx, int dy) {
    setState(() {
      _playerX += dx;
      _playerY += dy;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(title: const Text('Grid & Camera Demo'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          // Grid type selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildGridButton('Square', 0), const SizedBox(width: 16), _buildGridButton('Isometric', 1)],
            ),
          ),

          // Grid viewport
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapUp: (details) {
                    // Convert tap to grid coordinates
                    final worldPos = _camera.screenToWorld(details.localPosition, viewport);
                    final grid = _getGrid();
                    final gridCoord = grid.localToGrid(worldPos.x, worldPos.y);

                    setState(() {
                      _playerX = gridCoord.x;
                      _playerY = gridCoord.y;
                    });
                  },
                  child: CustomPaint(
                    size: viewport,
                    painter: _GridPainter(grid: _getGrid(), camera: _camera, playerX: _playerX, playerY: _playerY),
                  ),
                );
              },
            ),
          ),

          // Controls - different layout for each grid type
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _gridType == 0 ? _buildSquareControls() : _buildIsometricControls(),
          ),
        ],
      ),
    );
  }

  /// Standard D-pad for square grid
  Widget _buildSquareControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: () => _movePlayer(0, -1),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _movePlayer(-1, 0),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: () => _movePlayer(1, 0),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_downward, color: Colors.white),
              onPressed: () => _movePlayer(0, 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => _camera.shake(magnitude: 15, duration: 0.3), child: const Text('Shake!')),
      ],
    );
  }

  /// Diamond D-pad for isometric grid (visual directions match screen)
  Widget _buildIsometricControls() {
    return Column(
      children: [
        // Up-Left and Up-Right (visual top)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.north_west, color: Colors.white),
              onPressed: () => _movePlayer(-1, 0), // Visual NW = grid -X
              tooltip: 'NW (-X)',
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.north_east, color: Colors.white),
              onPressed: () => _movePlayer(0, -1), // Visual NE = grid -Y
              tooltip: 'NE (-Y)',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Down-Left and Down-Right (visual bottom)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.south_west, color: Colors.white),
              onPressed: () => _movePlayer(0, 1), // Visual SW = grid +Y
              tooltip: 'SW (+Y)',
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.south_east, color: Colors.white),
              onPressed: () => _movePlayer(1, 0), // Visual SE = grid +X
              tooltip: 'SE (+X)',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => _camera.shake(magnitude: 15, duration: 0.3), child: const Text('Shake!')),
      ],
    );
  }

  Widget _buildGridButton(String label, int type) {
    final selected = _gridType == type;
    return ElevatedButton(
      onPressed: () => setState(() => _gridType = type),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.cyanAccent : Colors.grey[800],
        foregroundColor: selected ? Colors.black : Colors.white,
      ),
      child: Text(label),
    );
  }
}

class _GridPainter extends CustomPainter {
  final FGrid grid;
  final FGridCamera camera;
  final int playerX;
  final int playerY;

  _GridPainter({required this.grid, required this.camera, required this.playerX, required this.playerY});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final playerPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    final originPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    // Get visible cells
    final visibleRect = camera.getVisibleRect(size);
    final topLeft = grid.localToGrid(visibleRect.left, visibleRect.top);
    final bottomRight = grid.localToGrid(visibleRect.right, visibleRect.bottom);

    // Draw grid cells
    for (int y = topLeft.y - 2; y <= bottomRight.y + 2; y++) {
      for (int x = topLeft.x - 2; x <= bottomRight.x + 2; x++) {
        final worldPos = grid.getCellCenter(x, y);
        final screenPos = camera.worldToScreen(v.Vector2(worldPos.dx, worldPos.dy), size);

        // Draw cell
        if (grid is FIsometricGrid) {
          final isoGrid = grid as FIsometricGrid;
          final polygon = isoGrid.getCellPolygon(x, y);
          final path = Path();

          final first = camera.worldToScreen(v.Vector2(polygon[0].dx, polygon[0].dy), size);
          path.moveTo(first.dx, first.dy);

          for (int i = 1; i < polygon.length; i++) {
            final p = camera.worldToScreen(v.Vector2(polygon[i].dx, polygon[i].dy), size);
            path.lineTo(p.dx, p.dy);
          }
          path.close();
          canvas.drawPath(path, gridPaint);
        } else {
          // Square grid
          final cellSize = grid.cellWidth * camera.zoom;
          canvas.drawRect(Rect.fromCenter(center: screenPos, width: cellSize, height: cellSize), gridPaint);
        }

        // Highlight origin
        if (x == 0 && y == 0) {
          canvas.drawCircle(screenPos, 8, originPaint);
        }
      }
    }

    // Draw player
    final playerWorld = grid.getCellCenter(playerX, playerY);
    final playerScreen = camera.worldToScreen(v.Vector2(playerWorld.dx, playerWorld.dy), size);
    canvas.drawCircle(playerScreen, 20, playerPaint);

    // Draw coordinates text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Player: ($playerX, $playerY)',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}
