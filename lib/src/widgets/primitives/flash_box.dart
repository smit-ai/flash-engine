import 'package:flutter/material.dart';
import '../../core/graph/node.dart';
import '../framework.dart';

class FBox extends FNodeWidget {
  final double width;
  final double height;
  final Color color;

  const FBox({
    super.key,
    super.position,
    super.rotation,
    super.scale,
    super.name,
    this.width = 1.0,
    this.height = 1.0,
    this.color = Colors.white,
    super.child,
    super.billboard,
  });

  @override
  State<FBox> createState() => _FBoxState();
}

class _FBoxState extends FNodeWidgetState<FBox, _BoxNode> {
  @override
  _BoxNode createNode() => _BoxNode(width: widget.width, height: widget.height, color: widget.color);

  @override
  void applyProperties([FBox? oldWidget]) {
    super.applyProperties(oldWidget);
    node.width = widget.width;
    node.height = widget.height;
    node.color = widget.color;
  }
}

class _BoxNode extends FNode {
  double width;
  double height;
  Color color;

  final Paint _paint = Paint();
  Color? _lastColor;
  double _lastBrightness = -1.0;

  _BoxNode({required this.width, required this.height, required this.color});

  @override
  void draw(Canvas canvas) {
    // Basic brightness logic
    double brightness = lights.isEmpty ? 1.0 : 0.2;

    if (lights.isNotEmpty) {
      final worldPos = worldPosition;
      final normal = worldMatrix.forward..normalize();

      for (final light in lights) {
        final lightPos = light.worldPosition;
        final lightDir = (lightPos - worldPos)..normalize();
        final dot = normal.dot(lightDir);
        if (dot > 0) {
          brightness += dot * light.intensity;
        }
      }
    }

    brightness = brightness.clamp(0.0, 1.0);

    // Update paint - use withOpacity for better compatibility and simplicity
    if (color != _lastColor || brightness != _lastBrightness) {
      _lastColor = color;
      _lastBrightness = brightness;

      // Calculate lit color
      final litColor = Color.from(
        alpha: color.a,
        red: color.r * brightness,
        green: color.g * brightness,
        blue: color.b * brightness,
      );
      _paint.color = litColor;
    }

    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    canvas.drawRect(rect, _paint);
  }

  @override
  Rect? get bounds => Rect.fromCenter(center: Offset.zero, width: width, height: height);
}
