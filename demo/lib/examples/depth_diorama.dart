import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:math';

class DepthDioramaExample extends StatefulWidget {
  const DepthDioramaExample({super.key});

  @override
  State<DepthDioramaExample> createState() => _DepthDioramaExampleState();
}

class _DepthDioramaExampleState extends State<DepthDioramaExample> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(title: const Text('2.5D Diorama Scene'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: FView(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi;

            return Stack(
              children: [
                // Camera
                FCamera(position: v.Vector3(0, 0, 800), fov: 60),

                // Lighting - Key light
                FLight(position: v.Vector3(300, 400, 600), color: Colors.white, intensity: 1.2),

                // Lighting - Fill light
                FLight(position: v.Vector3(-300, 200, 400), color: Colors.blueAccent, intensity: 0.6),

                // --- Sky/Background Layer (Z: -800 to -500) ---
                // Stars
                for (int i = 0; i < 30; i++)
                  FBox(
                    position: v.Vector3(
                      (Random(i).nextDouble() - 0.5) * 2000,
                      (Random(i + 100).nextDouble() - 0.5) * 1000,
                      -800 + Random(i + 200).nextDouble() * 200,
                    ),
                    width: 3,
                    height: 3,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),

                // --- Far Background Layer (Z: -400 to -200) ---
                // Distant mountains (triangles)
                for (int i = 0; i < 6; i++)
                  FTriangle(
                    position: v.Vector3((i - 2.5) * 350, -100, -350),
                    size: 400,
                    color: const Color(0xFF1a3c5a),
                  ),

                // --- Mid Background Layer (Z: -150 to 0) ---
                // Trees (darker green)
                for (int i = 0; i < 10; i++)
                  _buildTree(v.Vector3((i - 4.5) * 180, -150, -100 - i * 5.0), const Color(0xFF2d5a27), 120),

                // --- Mid-Foreground Layer (Z: 50 to 300) ---
                // Animated character orbiting
                FSphere(
                  position: v.Vector3(sin(t) * 350, cos(t * 0.8) * 100 - 50, cos(t * 0.7) * 250 + 150),
                  radius: 25,
                  color: Colors.cyanAccent,
                ),

                // Floating cubes
                for (int i = 0; i < 5; i++)
                  FBox(
                    position: v.Vector3(sin(t + i) * 300, cos(t * 0.5 + i) * 80, 100 + i * 40.0),
                    width: 30,
                    height: 30,
                    color: Color.lerp(Colors.purple, Colors.orange, i / 4)!,
                    rotation: v.Vector3(t + i, t * 0.7, t * 0.5),
                  ),

                // --- Foreground Layer (Z: 350 to 600) ---
                // Trees (lighter, closer)
                for (int i = 0; i < 8; i++)
                  _buildTree(v.Vector3((i - 3.5) * 200, -200, 400 + i * 20.0), const Color(0xFF3a6b35), 180),

                // Ground rocks
                for (int i = 0; i < 12; i++)
                  FBox(
                    position: v.Vector3((i - 5.5) * 130, -230, 500 + (Random(i + 500).nextDouble() - 0.5) * 100),
                    width: 40 + Random(i + 600).nextDouble() * 30,
                    height: 30 + Random(i + 700).nextDouble() * 20,
                    color: const Color(0xFF4a4a4a),
                    rotation: v.Vector3(0, 0, Random(i + 800).nextDouble() * 0.5),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTree(v.Vector3 position, Color color, double height) {
    return FNodes(
      position: position,
      children: [
        // Trunk
        FBox(
          position: v.Vector3(0, -height * 0.3, 0),
          width: height * 0.15,
          height: height * 0.6,
          color: const Color(0xFF3d2817),
        ),
        // Foliage (triangle)
        FTriangle(position: v.Vector3(0, height * 0.2, 0), size: height * 0.8, color: color),
      ],
    );
  }
}
