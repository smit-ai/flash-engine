import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class AudioDemo extends StatefulWidget {
  const AudioDemo({super.key});

  @override
  State<AudioDemo> createState() => _AudioDemoState();
}

class _AudioDemoState extends State<AudioDemo> {
  late final FPhysicsSystem _physicsWorld;

  @override
  void initState() {
    super.initState();
    _physicsWorld = FPhysicsSystem(gravity: FPhysics.standardGravity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Native Physics Audio Collision'), backgroundColor: Colors.transparent),
      body: FView(
        physicsWorld: _physicsWorld,
        autoUpdate: true,
        child: Stack(
          children: [
            FCamera(position: v.Vector3(0, 0, 800), fov: 60),

            // Floor
            FStaticBody(
              name: 'Floor',
              position: v.Vector3(0, -350, 0),
              width: 1200,
              height: 40,
              child: FBox(width: 1200, height: 40, color: Colors.white10),
            ),

            // Left Wall
            FStaticBody(
              name: 'LeftWall',
              position: v.Vector3(-450, 0, 0),
              width: 40,
              height: 800,
              child: FBox(width: 40, height: 800, color: Colors.white10),
            ),

            // Right Wall
            FStaticBody(
              name: 'RightWall',
              position: v.Vector3(450, 0, 0),
              width: 40,
              height: 800,
              child: FBox(width: 40, height: 800, color: Colors.white10),
            ),

            // Slider A (Moving Right)
            _buildSliderBox(position: v.Vector3(-200, -170, 0), velocity: v.Vector2(300, 0), color: Colors.cyanAccent),

            // Slider B (Moving Left)
            _buildSliderBox(position: v.Vector3(200, -170, 0), velocity: v.Vector2(-300, 0), color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderBox({required v.Vector3 position, required v.Vector2 velocity, required Color color}) {
    final controller = FAudioController();
    int lastPlayTime = 0;
    const int cooldownMs = 100; // Prevent spamming sounds

    return FRigidBody.square(
      position: position,
      initialVelocity: velocity,
      size: 40,
      onCollision: (body) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastPlayTime < cooldownMs) return;

        // Play sound on impact (detected by native core)
        controller.play();
        lastPlayTime = now;
      },
      child: Stack(
        children: [
          FBox(width: 40, height: 40, color: color),
          FAudioPlayer(assetPath: 'asset/demo.mp3', controller: controller, autoplay: false, is3D: false),
        ],
      ),
    );
  }
}
