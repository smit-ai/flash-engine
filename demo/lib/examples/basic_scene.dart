import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// Basic Scene Demo - showcasing core Flash Engine features with modern DX:
/// - FScene.sceneBuilder for declarative time-based animations (NO setState!)
/// - FCamera for 3D perspective
/// - FLight for dynamic lighting
/// - FSphere/FBox/FCube primitives with Z-sorting
/// - engine.elapsed for animation timing
class BasicSceneExample extends StatelessWidget {
  const BasicSceneExample({super.key});

  static final Random _rnd = Random(42); // Fixed seed for consistent demo
  static final List<_ShapeData> _shapes = List.generate(
    12,
    (i) => _ShapeData(
      type: i % 3, // 0=sphere, 1=box, 2=cube
      color: HSLColor.fromAHSL(1, i * 30.0, 0.7, 0.5).toColor(),
      size: 30.0 + _rnd.nextDouble() * 40.0,
      position: v.Vector3(
        (_rnd.nextDouble() - 0.5) * 400,
        (_rnd.nextDouble() - 0.5) * 300,
        (_rnd.nextDouble() - 0.5) * 200,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: FScene(
        // Use sceneBuilder for time-based animations - NO setState needed!
        sceneBuilder: (context, elapsed) => [
          // Camera
          FCamera(position: v.Vector3(0, 0, 500), fov: 60),

          // Orbiting light source
          FLight(
            position: v.Vector3(cos(elapsed * 0.5) * 200, sin(elapsed * 0.3) * 150, 100),
            color: Colors.white,
            intensity: 1.5,
          ),

          // Shapes - automatically Z-sorted by engine
          for (final shape in _shapes) _buildShape(shape, elapsed),
        ],

        // Flutter UI Overlay
        overlay: [
          // Title
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎮 Basic Scene',
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_shapes.length} shapes • Z-sorted • Dynamic light',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '✨ Using sceneBuilder (no setState!)',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            bottom: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Info badge
          Positioned(
            bottom: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
              ),
              child: const Text('FScene.sceneBuilder Demo', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildShape(_ShapeData shape, double elapsed) {
    // Rotate shapes based on elapsed time
    final rot = v.Vector3(
      elapsed * 0.3 + shape.position.x * 0.01,
      elapsed * 0.5 + shape.position.y * 0.01,
      elapsed * 0.2,
    );

    switch (shape.type) {
      case 0:
        return FSphere(position: shape.position, radius: shape.size / 2, color: shape.color);
      case 1:
        return FBox(
          position: shape.position,
          rotation: rot,
          width: shape.size,
          height: shape.size * 0.6,
          color: shape.color,
        );
      default:
        return FCube(position: shape.position, rotation: rot, size: shape.size * 0.8, color: shape.color);
    }
  }
}

class _ShapeData {
  final int type;
  final Color color;
  final double size;
  final v.Vector3 position;

  _ShapeData({required this.type, required this.color, required this.size, required this.position});
}
