import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:math';

class RenderingDemoExample extends StatefulWidget {
  const RenderingDemoExample({super.key});

  @override
  State<RenderingDemoExample> createState() => _RenderingDemoExampleState();
}

class _RenderingDemoExampleState extends State<RenderingDemoExample> {
  final List<v.Vector3> _pathPoints = [];
  late final FlashPhysicsSystem _physicsWorld;

  @override
  void initState() {
    super.initState();
    _physicsWorld = FlashPhysicsSystem(gravity: FlashPhysics.standardGravity);
    _generateWavyPath();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _generateWavyPath() {
    _pathPoints.clear();
    for (int i = 0; i < 40; i++) {
      final x = (i - 20) * 50.0;
      final y = sin(i * 0.4) * 80.0;
      _pathPoints.add(v.Vector3(x, y, 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(title: const Text('Renderers Demo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Flash(
        physicsWorld: _physicsWorld,
        autoUpdate: true, // Now this is all we need!
        child: Stack(
          children: [
            FlashCamera(position: v.Vector3(0, 0, 1800), fov: 60, far: 5000),

            // 1. LINE RENDERER: Ground
            FlashStaticBody.square(
              name: 'Ground',
              position: v.Vector3(0, -350, 0),
              size: 1000,
              child: FlashLineRenderer(
                name: 'WavyPath',
                points: _pathPoints,
                width: 15,
                glow: true,
                gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.cyanAccent, Colors.purpleAccent]),
              ),
            ),

            // 2. LINE RENDERER: Pulsing Orbit
            Builder(
              builder: (context) {
                final orbitRotation = (DateTime.now().millisecondsSinceEpoch / 1000.0) * 1.5;
                return FlashNodeGroup(
                  position: v.Vector3(0, 200, 0),
                  rotation: v.Vector3(0, 0, orbitRotation),
                  scale: v.Vector3.all(0.8 + sin(orbitRotation) * 0.2),
                  child: FlashLineRenderer(
                    name: 'CirclePath',
                    points: _generateCirclePoints(150, 4),
                    isLoop: true,
                    width: 12,
                    color: Colors.white24,
                  ),
                );
              },
            ),

            // 3. TRAIL RENDERER: Bouncing Physics Ball
            FlashRigidBody.circle(
              name: 'TrailBall',
              position: v.Vector3(-300, 500, 0),
              initialVelocity: v.Vector2(400, -200),
              radius: 30,
              child: FlashNodes(
                children: [
                  FlashCircle(radius: 30, color: Colors.orangeAccent),
                  const FlashTrailRenderer(
                    lifetime: 1.5,
                    startWidth: 25,
                    endWidth: 0,
                    startColor: Colors.orangeAccent,
                    endColor: Colors.transparent,
                  ),
                ],
              ),
            ),

            FlashRigidBody.square(
              name: 'DynamicObstacle',
              position: v.Vector3(-150, 0, 0),
              size: 60,
              initialVelocity: v.Vector2(100, 0),
              child: const FlashBox(width: 60, height: 60, color: Colors.redAccent),
            ),

            // Side Walls
            FlashStaticBody(
              name: 'Ground',
              position: v.Vector3(0, -350, 0),
              width: 800,
              height: 40,
              child: FlashBox(width: 800, height: 40, color: Colors.blueGrey),
            ),
            FlashStaticBody(
              name: 'LeftWall',
              position: v.Vector3(-600, 0, 0),
              width: 40,
              height: 2000,
              child: FlashBox(width: 40, height: 2000, color: Colors.cyanAccent.withValues(alpha: 0.1)),
            ),
            FlashStaticBody(
              name: 'RightWall',
              position: v.Vector3(600, 0, 0),
              width: 40,
              height: 2000,
              child: FlashBox(width: 40, height: 2000, color: Colors.cyanAccent.withValues(alpha: 0.1)),
            ),

            // Legend
            Positioned(
              left: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _debugInfo('LineRenderer:', 'Pulsing square orbit', Colors.cyanAccent),
                  _debugInfo('TrailRenderer:', 'Dynamic ball with physics', Colors.orangeAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<v.Vector3> _generateCirclePoints(double radius, int segments) {
    return List.generate(segments, (i) {
      final angle = (i / segments) * pi * 2;
      return v.Vector3(cos(angle) * radius, sin(angle) * radius, 0);
    });
  }

  Widget _debugInfo(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
