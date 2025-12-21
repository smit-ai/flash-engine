import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class CollisionLayersDemoExample extends StatefulWidget {
  const CollisionLayersDemoExample({super.key});

  @override
  State<CollisionLayersDemoExample> createState() => _CollisionLayersDemoExampleState();
}

class _CollisionLayersDemoExampleState extends State<CollisionLayersDemoExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        title: const Text('Native Physics Performance Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Flash(
        child: Stack(
          children: [
            // Camera
            FlashCamera(position: v.Vector3(0, 0, 1000), fov: 60),

            // Physics World
            FlashPhysicsWorld(gravity: FlashPhysics.standardGravity),

            // Static Floor
            FlashStaticBody(
              name: 'Ground',
              position: v.Vector3(0, -350, 0),
              width: 800,
              height: 40,
              child: FlashBox(width: 800, height: 40, color: Colors.white12),
            ),

            // MANY BLUE BOXES (Native high performance test)
            for (int i = 0; i < 20; i++)
              FlashRigidBody.square(
                key: ValueKey('blue_$i'),
                name: 'BlueBox',
                position: v.Vector3(-150 + (i * 20), 400 + (i * 60), 0),
                size: 30,
                child: const FlashBox(width: 30, height: 30, color: Colors.cyanAccent),
              ),

            // MANY RED BOXES
            for (int i = 0; i < 20; i++)
              FlashRigidBody.square(
                key: ValueKey('red_$i'),
                name: 'RedBox',
                position: v.Vector3(150 - (i * 20), 400 + (i * 60), 0),
                size: 30,
                child: const FlashBox(width: 30, height: 30, color: Colors.redAccent),
              ),

            // UI Overlay
            Positioned(
              left: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NATIVE PHYSICS ENABLED',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Active Objects: 41', style: TextStyle(color: Colors.white70)),
                  Text('Solver: Native C++ Circle', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {}), // Reset/Refresh
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
