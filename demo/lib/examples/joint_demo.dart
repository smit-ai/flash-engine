import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class JointDemoExample extends StatefulWidget {
  const JointDemoExample({super.key});

  @override
  State<JointDemoExample> createState() => _JointDemoExampleState();
}

class _JointDemoExampleState extends State<JointDemoExample> {
  late FlashRopeJoint _rope;
  v.Vector3 _anchorPos = v.Vector3(0, 150, 0);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _rope = FlashRopeJoint(
      anchorA: _anchorPos,
      segments: 15,
      totalLength: 250,
      gravity: v.Vector3(0, -300, 0),
      damping: 0.98,
      constraintIterations: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(title: const Text('Joint System Demo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Flash(
        child: Builder(
          builder: (context) {
            final engineWidget = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
            final engine = engineWidget?.engine;

            if (engine != null) {
              engine.onUpdate = () {
                final dt = 1 / 60.0;

                // Update rope anchor position
                _rope.movePoint(0, _anchorPos);
                _rope.update(dt);

                setState(() {});
              };
            }

            return GestureDetector(
              onPanStart: (details) {
                _isDragging = true;
              },
              onPanUpdate: (details) {
                if (_isDragging) {
                  final size = MediaQuery.of(context).size;
                  // Convert screen to world coordinates
                  final screenX = details.localPosition.dx - size.width / 2;
                  final screenY = -(details.localPosition.dy - size.height / 2);
                  _anchorPos = v.Vector3(screenX * 0.8, screenY * 0.8, 0);
                }
              },
              onPanEnd: (_) {
                _isDragging = false;
              },
              child: Stack(
                children: [
                  // Camera
                  FlashCameraWidget(position: v.Vector3(0, 0, 500), fov: 60),

                  // Custom painter for rope
                  CustomPaint(
                    size: Size.infinite,
                    painter: _RopePainter(positions: _rope.positions, screenCenter: MediaQuery.of(context).size / 2),
                  ),

                  // Anchor point indicator
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 + _anchorPos.x / 0.8 - 15,
                    top: MediaQuery.of(context).size.height / 2 - _anchorPos.y / 0.8 - 15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5),
                        ],
                      ),
                    ),
                  ),

                  // Instructions
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🔗 Rope Physics',
                              style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Drag the orange ball to swing the rope!',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Verlet Integration • 15 Segments',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RopePainter extends CustomPainter {
  final List<v.Vector3> positions;
  final Size screenCenter;

  _RopePainter({required this.positions, required this.screenCenter});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Convert first point
    final firstX = screenCenter.width + positions.first.x / 0.8;
    final firstY = screenCenter.height - positions.first.y / 0.8;
    path.moveTo(firstX, firstY);

    // Draw rope segments
    for (int i = 1; i < positions.length; i++) {
      final x = screenCenter.width + positions[i].x / 0.8;
      final y = screenCenter.height - positions[i].y / 0.8;
      path.lineTo(x, y);
    }

    // Draw glow
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    // Draw main rope
    paint.shader = LinearGradient(
      colors: [Colors.cyanAccent, Colors.purpleAccent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Draw nodes
    final nodePaint = Paint()..color = Colors.white;
    for (int i = 0; i < positions.length; i++) {
      final x = screenCenter.width + positions[i].x / 0.8;
      final y = screenCenter.height - positions[i].y / 0.8;
      canvas.drawCircle(Offset(x, y), i == positions.length - 1 ? 8 : 4, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RopePainter oldDelegate) => true;
}
