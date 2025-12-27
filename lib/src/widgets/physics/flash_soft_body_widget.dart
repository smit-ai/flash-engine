import 'package:flutter/material.dart';
import '../../core/systems/physics.dart';
import '../framework.dart';

class FSoftBodyWidget extends FNodeWidget {
  final WorldId world;
  final List<Offset> initialPoints;
  final double pressure;
  final double stiffness;

  const FSoftBodyWidget({
    super.key,
    required this.world,
    required this.initialPoints,
    this.pressure = 1.0,
    this.stiffness = 1.0,
    super.name = 'SoftBody',
  });

  @override
  State<FSoftBodyWidget> createState() => _FSoftBodyWidgetState();
}

class _FSoftBodyWidgetState extends FNodeWidgetState<FSoftBodyWidget, FSoftBody> {
  @override
  FSoftBody createNode() => FSoftBody(
    world: widget.world,
    initialPoints: widget.initialPoints,
    pressure: widget.pressure,
    stiffness: widget.stiffness,
  );

  @override
  void applyProperties([FSoftBodyWidget? oldWidget]) {
    super.applyProperties(oldWidget);
    // Note: If pressure/stiffness change, we would ideally update the native struct.
    // For now, these are initial parameters.
  }
}
