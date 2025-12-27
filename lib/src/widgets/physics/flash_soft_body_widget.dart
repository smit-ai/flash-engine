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
    if (oldWidget != null && (widget.pressure != oldWidget.pressure || widget.stiffness != oldWidget.stiffness)) {
      node.setParams(widget.pressure, widget.stiffness);
    }
  }
}
