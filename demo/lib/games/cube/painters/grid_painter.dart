import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double cameraX;
  final double cameraZ;
  final double gridSize;
  final Color color;

  const GridPainter({required this.cameraX, required this.cameraZ, required this.gridSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final halfGrid = gridSize / 2.0;
    const range = 1200.0;
    final halfRange = range / 2.0;

    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;

    final double offsetX = -(cameraX % gridSize);
    final double offsetZ = -(cameraZ % gridSize);

    for (double i = -halfRange; i <= halfRange + gridSize; i += gridSize) {
      final x = i + offsetX + halfGrid;
      final z = i + offsetZ + halfGrid;

      if (x >= -halfRange && x <= halfRange) {
        canvas.drawLine(Offset(centerX + x, centerY - halfRange), Offset(centerX + x, centerY + halfRange), paint);
      }
      if (z >= -halfRange && z <= halfRange) {
        canvas.drawLine(Offset(centerX - halfRange, centerY + z), Offset(centerX + halfRange, centerY + z), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.cameraX != cameraX ||
      oldDelegate.cameraZ != cameraZ ||
      oldDelegate.gridSize != gridSize ||
      oldDelegate.color != color;
}
