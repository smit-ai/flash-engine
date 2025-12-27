import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:math';
import '../layout/group.dart';
import 'flash_box.dart';

class FCube extends StatelessWidget {
  final double size;
  final Color color;
  final v.Vector3? position;
  final v.Vector3? rotation;
  final v.Vector3? scale;
  final String? name;

  const FCube({
    super.key,
    this.size = 100,
    this.color = Colors.white,
    this.position,
    this.rotation,
    this.scale,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final half = size / 2;
    return FNodes(
      name: name ?? 'Cube',
      position: position,
      rotation: rotation,
      scale: scale,
      children: [
        // Front
        FBox(name: 'Front', position: v.Vector3(0, 0, half), width: size, height: size, color: color),
        // Back
        FBox(
          name: 'Back',
          position: v.Vector3(0, 0, -half),
          rotation: v.Vector3(0, pi, 0),
          width: size,
          height: size,
          color: color.withValues(alpha: 0.8),
        ),
        // Top
        FBox(
          name: 'Top',
          position: v.Vector3(0, half, 0),
          rotation: v.Vector3(-pi / 2, 0, 0),
          width: size,
          height: size,
          color: color.withValues(alpha: 0.9),
        ),
        // Bottom
        FBox(
          name: 'Bottom',
          position: v.Vector3(0, -half, 0),
          rotation: v.Vector3(pi / 2, 0, 0),
          width: size,
          height: size,
          color: color.withValues(alpha: 0.7),
        ),
        // Left
        FBox(
          name: 'Left',
          position: v.Vector3(-half, 0, 0),
          rotation: v.Vector3(0, -pi / 2, 0),
          width: size,
          height: size,
          color: color.withValues(alpha: 0.75),
        ),
        // Right
        FBox(
          name: 'Right',
          position: v.Vector3(half, 0, 0),
          rotation: v.Vector3(0, pi / 2, 0),
          width: size,
          height: size,
          color: color.withValues(alpha: 0.85),
        ),
      ],
    );
  }
}
