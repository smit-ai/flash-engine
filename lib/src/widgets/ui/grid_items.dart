import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Generic floating item widget with animation.
///
/// Use for collectibles, power-ups, portals, etc.
class FFloatingItem extends StatefulWidget {
  /// Child widget to display
  final Widget child;

  /// Float animation amplitude
  final double floatAmplitude;

  /// Float animation duration
  final Duration floatDuration;

  /// Whether to rotate
  final bool rotate;

  /// Rotation duration
  final Duration rotationDuration;

  /// Whether to show glow
  final bool glow;

  /// Glow color
  final Color glowColor;

  /// Size of the item
  final double size;

  const FFloatingItem({
    super.key,
    required this.child,
    this.floatAmplitude = 4.0,
    this.floatDuration = const Duration(milliseconds: 1500),
    this.rotate = false,
    this.rotationDuration = const Duration(seconds: 3),
    this.glow = false,
    this.glowColor = Colors.white,
    this.size = 50,
  });

  @override
  State<FFloatingItem> createState() => _FFloatingItemState();
}

class _FFloatingItemState extends State<FFloatingItem> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController? _rotateController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(vsync: this, duration: widget.floatDuration)..repeat(reverse: true);

    if (widget.rotate) {
      _rotateController = AnimationController(vsync: this, duration: widget.rotationDuration)..repeat();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    // Rotation
    if (_rotateController != null) {
      child = AnimatedBuilder(
        animation: _rotateController!,
        builder: (context, child) {
          return Transform.rotate(angle: _rotateController!.value * math.pi * 2, child: child);
        },
        child: child,
      );
    }

    // Float animation
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = math.sin(_floatController.value * math.pi) * widget.floatAmplitude;

        return Transform.translate(
          offset: Offset(0, -offset),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              if (widget.glow)
                Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: widget.glowColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 5),
                    ],
                  ),
                ),
              child!,
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// Diamond collectible widget.
class FDiamondWidget extends StatelessWidget {
  /// Diamond color
  final Color color;

  /// Size
  final double size;

  const FDiamondWidget({super.key, this.color = Colors.cyan, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return FFloatingItem(
      rotate: true,
      glow: true,
      glowColor: color,
      size: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DiamondPainter(color: color),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final Color color;

  _DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();

    // Gradient fill
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.9), Color.lerp(color, Colors.white, 0.5)!],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Star collectible widget.
class FStarWidget extends StatelessWidget {
  /// Star color
  final Color color;

  /// Size
  final double size;

  /// Number of points
  final int points;

  const FStarWidget({super.key, this.color = Colors.amber, this.size = 30, this.points = 5});

  @override
  Widget build(BuildContext context) {
    return FFloatingItem(
      rotate: true,
      rotationDuration: const Duration(seconds: 4),
      glow: true,
      glowColor: color,
      size: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _StarPainter(color: color, points: points),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final int points;

  _StarPainter({required this.color, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.45;
    final innerR = outerR * 0.4;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, color],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: outerR)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Heart collectible widget.
class FHeartWidget extends StatelessWidget {
  /// Heart color
  final Color color;

  /// Size
  final double size;

  const FHeartWidget({super.key, this.color = Colors.red, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return FFloatingItem(
      glow: true,
      glowColor: color,
      size: size,
      child: Icon(Icons.favorite, color: color, size: size * 0.8),
    );
  }
}

/// Portal/teleport widget with swirl effect.
class FPortalWidget extends StatefulWidget {
  /// Portal color
  final Color color;

  /// Size
  final double size;

  const FPortalWidget({super.key, this.color = Colors.purple, this.size = 50});

  @override
  State<FPortalWidget> createState() => _FPortalWidgetState();
}

class _FPortalWidgetState extends State<FPortalWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PortalPainter(color: widget.color, progress: _controller.value),
        );
      },
    );
  }
}

class _PortalPainter extends CustomPainter {
  final Color color;
  final double progress;

  _PortalPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.2,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Spiral rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final ringR = r * (0.3 + ringProgress * 0.7);
      final alpha = (1 - ringProgress) * 0.6;

      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Center
    canvas.drawCircle(Offset(cx, cy), r * 0.2, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _PortalPainter oldDelegate) => oldDelegate.progress != progress;
}
