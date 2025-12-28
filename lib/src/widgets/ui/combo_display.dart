import 'package:flutter/material.dart';

/// Combo display widget with animation and styling.
///
/// Shows the current combo multiplier with visual feedback.
///
/// Example:
/// ```dart
/// FComboDisplay(
///   multiplier: 5,
///   count: 12,
/// )
/// ```
class FComboDisplay extends StatelessWidget {
  /// Current combo multiplier
  final int multiplier;

  /// Total combo count (for animation key)
  final int count;

  /// Color function based on multiplier
  final Color Function(int multiplier)? colorBuilder;

  /// Custom icon
  final IconData icon;

  /// Text style override
  final TextStyle? textStyle;

  const FComboDisplay({
    super.key,
    required this.multiplier,
    this.count = 0,
    this.colorBuilder,
    this.icon = Icons.local_fire_department,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (multiplier <= 1) return const SizedBox.shrink();

    final color = colorBuilder?.call(multiplier) ?? _defaultColor(multiplier);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.5, end: 1.0),
      duration: const Duration(milliseconds: 200),
      key: ValueKey(count),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), Color.lerp(color, Colors.black, 0.3)!.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 4),
                Text(
                  '${multiplier}x COMBO!',
                  style:
                      textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 1))],
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _defaultColor(int multiplier) {
    if (multiplier >= 10) return Colors.purple;
    if (multiplier >= 7) return Colors.red;
    if (multiplier >= 5) return Colors.orange;
    if (multiplier >= 3) return Colors.yellow.shade700;
    return Colors.green;
  }
}

/// Active power-up indicator badge.
class FPowerUpIndicator extends StatelessWidget {
  /// Power-up name
  final String name;

  /// Badge color
  final Color color;

  /// Remaining duration
  final Duration remaining;

  /// Custom icon
  final IconData icon;

  const FPowerUpIndicator({
    super.key,
    required this.name,
    required this.color,
    required this.remaining,
    this.icon = Icons.bolt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$name ${remaining.inSeconds}s',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
