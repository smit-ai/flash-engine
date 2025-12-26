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
  final bool isBullet;

  BoxData({
    required this.id,
    required this.position,
    this.rotation,
    required this.size,
    required this.color,
    this.isCircle = false,
    this.isBullet = false,
  });
}

class _PhysicsDemoExampleState extends State<PhysicsDemoExample> {
  final List<BoxData> boxes = [];
  final Random random = Random();
  bool stressTestMode = false;
  bool warmStarting = true;
  double contactHertz = 30.0;
  double dampingRatio = 0.8;

  @override
  void initState() {
    super.initState();
    // Start with moderate number of bodies
    for (int i = 0; i < 20; i++) {
      _addRandomBox();
    }
  }

  void _addRandomBox({bool bullet = false}) {
    final isCircle = Random().nextBool();
    final size = bullet ? 15.0 : (30.0 + Random().nextDouble() * 30.0);
    final color = bullet ? Colors.red : Colors.accents[Random().nextInt(Colors.accents.length)];
    // No initial rotation - let physics handle it naturally
    final rotation = v.Vector3(0, 0, 0);
    final x = (Random().nextDouble() - 0.5) * 200;
    final y = bullet ? 300.0 : (200.0 + Random().nextDouble() * 100);

    setState(() {
      boxes.add(
        BoxData(
          id: 'body_${boxes.length}',
          position: v.Vector3(x, y, 0),
          rotation: rotation,
          size: size,
          color: color,
          isCircle: isCircle,
          isBullet: bullet,
        ),
      );
    });
  }

  void _toggleStressTest() {
    setState(() {
      stressTestMode = !stressTestMode;
      if (stressTestMode) {
        // Add 100 more bodies for stress test
        for (int i = 0; i < 100; i++) {
          _addRandomBox();
        }
      } else {
        // Remove extra bodies
        boxes.removeRange(20, boxes.length);
      }
    });
  }

  void _shootBullet() {
    _addRandomBox(bullet: true);
  }

  void _clearAll() {
    setState(() {
      boxes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bodyCount = boxes.length + 5; // +5 for static bodies
    final expectedChecks = stressTestMode ? '~${bodyCount * 2} (Broadphase)' : '~${bodyCount * 2} (Broadphase)';
    final oldChecks = stressTestMode
        ? '~${(bodyCount * (bodyCount - 1) / 2).toInt()} (O(n²))'
        : '~${(bodyCount * (bodyCount - 1) / 2).toInt()} (O(n²))';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Box2D Physics Engine Demo'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(stressTestMode ? Icons.speed : Icons.speed_outlined),
            onPressed: _toggleStressTest,
            tooltip: 'Stress Test (${stressTestMode ? "ON" : "OFF"})',
          ),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearAll, tooltip: 'Clear All'),
        ],
      ),
      body: Flash(
        child: Stack(
          children: [
            // Camera
            FlashCamera(position: v.Vector3(0, 0, 800)),

            // Ground
            FlashStaticBody(
              name: 'Ground',
              position: v.Vector3(0, -350, 0),
              width: 900,
              height: 40,
              child: FlashBox(width: 900, height: 40, color: Colors.grey[800]!),
            ),

            // Left Wall
            FlashStaticBody(
              name: 'LeftWall',
              position: v.Vector3(-450, 0, 0),
              width: 40,
              height: 800,
              child: FlashBox(width: 40, height: 800, color: Colors.grey[800]!.withValues(alpha: 0.5)),
            ),

            // Right Wall
            FlashStaticBody(
              name: 'RightWall',
              position: v.Vector3(450, 0, 0),
              width: 40,
              height: 800,
              child: FlashBox(width: 40, height: 800, color: Colors.grey[800]!.withValues(alpha: 0.5)),
            ),

            // Top Left Ramp
            FlashStaticBody(
              name: 'TopLeftRamp',
              position: v.Vector3(-180, 200, 0),
              rotation: v.Vector3(0, 0, -0.6),
              width: 200,
              height: 20,
              child: FlashBox(width: 200, height: 20, color: Colors.orange.withValues(alpha: 0.7)),
            ),

            // Top Right Ramp
            FlashStaticBody(
              name: 'TopRightRamp',
              position: v.Vector3(180, 180, 0),
              rotation: v.Vector3(0, 0, 0.6),
              width: 200,
              height: 20,
              child: FlashBox(width: 200, height: 20, color: Colors.orange.withValues(alpha: 0.7)),
            ),

            // Left Ramp (Upper Middle)
            FlashStaticBody(
              name: 'LeftRamp',
              position: v.Vector3(-200, 80, 0),
              rotation: v.Vector3(0, 0, -0.5),
              width: 220,
              height: 20,
              child: FlashBox(width: 220, height: 20, color: Colors.blueGrey.withValues(alpha: 0.7)),
            ),

            // Right Ramp (Middle)
            FlashStaticBody(
              name: 'RightRamp',
              position: v.Vector3(200, 40, 0),
              rotation: v.Vector3(0, 0, 0.5),
              width: 220,
              height: 20,
              child: FlashBox(width: 220, height: 20, color: Colors.blueGrey.withValues(alpha: 0.7)),
            ),

            // Left Lower Ramp
            FlashStaticBody(
              name: 'LeftLowerRamp',
              position: v.Vector3(-150, -80, 0),
              rotation: v.Vector3(0, 0, -0.4),
              width: 180,
              height: 20,
              child: FlashBox(width: 180, height: 20, color: Colors.teal.withValues(alpha: 0.7)),
            ),

            // Right Lower Ramp
            FlashStaticBody(
              name: 'RightLowerRamp',
              position: v.Vector3(150, -120, 0),
              rotation: v.Vector3(0, 0, 0.4),
              width: 180,
              height: 20,
              child: FlashBox(width: 180, height: 20, color: Colors.teal.withValues(alpha: 0.7)),
            ),

            // Dynamic Bodies
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

            // Enhanced HUD
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'BOX2D PHYSICS ENGINE',
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.cyanAccent, height: 16),
                    _buildInfoRow('Bodies', '$bodyCount'),
                    _buildInfoRow('Solver', 'Sequential Impulse'),
                    _buildInfoRow('Iterations', '8 velocity, 6 position'),
                    _buildInfoRow('Warm Start', warmStarting ? 'ON' : 'OFF', color: Colors.greenAccent),
                    _buildInfoRow('Contact Freq', '${contactHertz.toInt()}Hz'),
                    _buildInfoRow('Damping', dampingRatio.toStringAsFixed(1)),
                    const SizedBox(height: 8),
                    const Text(
                      'BROADPHASE OPTIMIZATION',
                      style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    _buildInfoRow('Algorithm', 'Spatial Hash Grid'),
                    _buildInfoRow('New Checks', expectedChecks, color: Colors.greenAccent),
                    _buildInfoRow('Old Checks', oldChecks, color: Colors.redAccent),
                    if (stressTestMode)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⚡ STRESS TEST MODE',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Controls HUD
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'add',
                    onPressed: () => _addRandomBox(),
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'bullet',
                    onPressed: _shootBullet,
                    backgroundColor: Colors.red,
                    mini: true,
                    child: const Icon(Icons.flash_on),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          Text(
            value,
            style: TextStyle(color: color ?? Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
