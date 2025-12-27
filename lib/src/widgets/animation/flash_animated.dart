import 'package:flutter/widgets.dart';
import '../framework.dart';

/// FAnimated - A declarative animation widget that rebuilds on every engine frame.
///
/// Provides `elapsed` time (in seconds) to the builder for time-based animations
/// without manual setState calls.
///
/// Example:
/// ```dart
/// FAnimated(
///   builder: (context, elapsed) => FSphere(
///     position: v.Vector3(sin(elapsed) * 100, 0, 0),
///   ),
/// )
/// ```
class FAnimated extends StatelessWidget {
  /// Builder that receives current context and elapsed time in seconds.
  final Widget Function(BuildContext context, double elapsed) builder;

  const FAnimated({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final engine = context.flash;
    if (engine == null) {
      return const SizedBox.shrink();
    }
    return builder(context, engine.elapsed);
  }
}

/// FAnimatedList - A declarative animation widget that builds a list of widgets.
///
/// Useful for building multiple animated elements from the same elapsed time.
///
/// Example:
/// ```dart
/// FAnimatedList(
///   builder: (context, elapsed) => [
///     FSphere(position: v.Vector3(sin(elapsed) * 100, 0, 0)),
///     FBox(rotation: v.Vector3(0, elapsed, 0)),
///   ],
/// )
/// ```
class FAnimatedList extends StatelessWidget {
  /// Builder that receives current context and elapsed time in seconds.
  /// Returns a list of widgets to display.
  final List<Widget> Function(BuildContext context, double elapsed) builder;

  const FAnimatedList({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final engine = context.flash;
    if (engine == null) {
      return const SizedBox.shrink();
    }
    final widgets = builder(context, engine.elapsed);
    return Stack(children: widgets);
  }
}
