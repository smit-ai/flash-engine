import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// Native Physics Collision Layers Demo
/// Demonstrates Box2D-style category/mask filtering.
class CollisionLayersDemoExample extends StatefulWidget {
  const CollisionLayersDemoExample({super.key});

  @override
  State<CollisionLayersDemoExample> createState() => _CollisionLayersDemoExampleState();
}

class _CollisionLayersDemoExampleState extends State<CollisionLayersDemoExample> {
  int _resetKey = 0;

  void _reset() => setState(() => _resetKey++);

  @override
  Widget build(BuildContext context) {
    // Layer Definitions
    const int groundLayer = 0x0001;
    const int blueLayer = 0x0002;
    const int redLayer = 0x0004;
    const int greenLayer = 0x0008;

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(title: const Text('Collision Layers Demo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: FScene(
        key: ValueKey(_resetKey),

        scene: [
          FCamera(position: v.Vector3(0, 0, 1000), fov: 60),
          FPhysicsWorld(gravity: FPhysics.standardGravity),

          // GROUND: Layer 0x1. Collides with EVERYTHING (Mask 0xFFFF)
          FStaticBody(
            name: 'Ground',
            position: v.Vector3(0, -350, 0),
            width: 800,
            height: 40,
            categoryBits: groundLayer,
            maskBits: 0xFFFF,
            child: const FBox(width: 800, height: 40, color: Colors.white12),
          ),

          // BLUE BOXES: Layer 0x2
          // Mask 0x3 (0x1 | 0x2) -> Collides with Ground (0x1) and Blue (0x2).
          // Does NOT collide with Red (0x4).
          for (int i = 0; i < 20; i++)
            FRigidBody.square(
              key: ValueKey('blue_$i'),
              name: 'BlueBox',
              position: v.Vector3(-150 + (i * 20), 400 + (i * 60), 0),
              size: 30,
              categoryBits: blueLayer,
              maskBits: groundLayer | blueLayer,
              child: const FBox(width: 30, height: 30, color: Colors.cyanAccent),
            ),

          // RED BOXES: Layer 0x4
          // Mask 0x5 (0x1 | 0x4) -> Collides with Ground (0x1) and Red (0x4).
          // Does NOT collide with Blue (0x2).
          for (int i = 0; i < 20; i++)
            FRigidBody.square(
              key: ValueKey('red_$i'),
              name: 'RedBox',
              position: v.Vector3(150 - (i * 20), 400 + (i * 60), 0),
              size: 30,
              categoryBits: redLayer,
              maskBits: groundLayer | redLayer,
              child: const FBox(width: 30, height: 30, color: Colors.redAccent),
            ),

          // GREEN BOXES: Layer 0x8
          // Mask 0x8 -> Only collides with other Green boxes.
          // Does NOT collide with Ground (0x1), Blue (0x2), or Red (0x4).
          for (int i = 0; i < 10; i++)
            FRigidBody.square(
              key: ValueKey('green_$i'),
              name: 'GreenBox',
              position: v.Vector3(-50 + (i * 10), 600 + (i * 60), 0),
              size: 30,
              categoryBits: greenLayer,
              maskBits: greenLayer,
              child: const FBox(width: 30, height: 30, color: Colors.greenAccent),
            ),
        ],

        overlay: [
          Positioned(
            left: 20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'COLLISION FILTERING',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendEntry(Colors.cyanAccent, 'Blue: Collides with Blue & Ground'),
                  _buildLegendEntry(Colors.redAccent, 'Red: Collides with Red & Ground'),
                  _buildLegendEntry(Colors.greenAccent, 'Green: Collides ONLY with Green'),
                  const SizedBox(height: 8),
                  const Text(
                    '✨ Green passes through everything BUT Green!',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const Text(
                    '✨ Red and Blue pass through each other!',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _reset, child: const Icon(Icons.refresh)),
    );
  }

  Widget _buildLegendEntry(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
