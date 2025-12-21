import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:math';

class PhysicsDemoExample extends StatefulWidget {
  const PhysicsDemoExample({super.key});

  @override
  State<PhysicsDemoExample> createState() => _PhysicsDemoExampleState();
}

class BoxData {
  final String id;
  final v.Vector3 position;
  final v.Vector3? rotation;
  final double size;
  final Color color;
  final bool isCircle;

  BoxData({
    required this.id,
    required this.position,
    this.rotation,
    required this.size,
    required this.color,
    this.isCircle = false,
  });
}

class _PhysicsDemoExampleState extends State<PhysicsDemoExample> {
  final List<BoxData> boxes = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _addRandomBox();
    }
  }

  void _addRandomBox() {
    final isCircle = Random().nextBool();
    final size = 30.0 + Random().nextDouble() * 30.0;
    final color = Colors.accents[Random().nextInt(Colors.accents.length)];
    final rotation = v.Vector3(0, 0, Random().nextDouble() * pi * 2);
    final x = (Random().nextDouble() - 0.5) * 200;

    setState(() {
      boxes.add(
        BoxData(
          id: 'body_${boxes.length}',
          position: v.Vector3(x, 500, 0),
          rotation: rotation,
          size: size,
          color: color,
          isCircle: isCircle,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native Physics Demo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Flash(
        // The Flash widget now handles native physics by default
        child: Stack(
          children: [
            // Camera
            FlashCamera(position: v.Vector3(0, 0, 800)),

            // Ground
            FlashStaticBody(
              name: 'Ground',
              position: v.Vector3(0, -350, 0),
              width: 800,
              height: 40,
              child: FlashBox(width: 800, height: 40, color: Colors.blueGrey),
            ),

            // Left Ramp
            FlashStaticBody(
              name: 'LeftRamp',
              position: v.Vector3(-250, 100, 0),
              rotation: v.Vector3(0, 0, -0.3),
              width: 300,
              height: 20,
              child: FlashBox(width: 300, height: 20, color: Colors.blueGrey.withValues(alpha: 0.3)),
            ),

            // Right Ramp
            FlashStaticBody(
              name: 'RightRamp',
              position: v.Vector3(250, -50, 0),
              rotation: v.Vector3(0, 0, 0.4),
              width: 300,
              height: 20,
              child: FlashBox(width: 300, height: 20, color: Colors.blueGrey.withValues(alpha: 0.3)),
            ),

            // Extreme Ramp (Top Left)
            FlashStaticBody(
              name: 'ExtremeRamp',
              position: v.Vector3(-200, 300, 0),
              rotation: v.Vector3(0, 0, -0.8), // Steeper
              width: 200,
              height: 20,
              child: FlashBox(width: 200, height: 20, color: Colors.blueGrey.withValues(alpha: 0.3)),
            ),

            // Center Pin (Circle)
            FlashStaticBody.circle(
              name: 'Pin',
              position: v.Vector3(0, -150, 0),
              radius: 40,
              child: FlashCircle(radius: 40, color: Colors.blueGrey),
            ),

            // dynamic Bodies
            for (final box in boxes)
              if (box.isCircle)
                FlashRigidBody.circle(
                  key: ValueKey(box.id),
                  name: box.id,
                  position: box.position,
                  radius: box.size / 2,
                  child: FlashCircle(radius: box.size / 2, color: box.color),
                )
              else
                FlashRigidBody.square(
                  key: ValueKey(box.id),
                  name: box.id,
                  position: box.position,
                  rotation: box.rotation,
                  size: box.size,
                  child: FlashBox(width: box.size, height: box.size, color: box.color),
                ),

            // HUD
            Positioned(
              left: 20,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PHYSICS ENGINE v2 (Native)',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Active Bodies: ${boxes.length + 4}', style: const TextStyle(color: Colors.white70)),
                    const Text(
                      'Mode: Sequential Impulse (12 iterations)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Text('Stabilization: Baumgarte', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addRandomBox, child: const Icon(Icons.add)),
    );
  }
}
