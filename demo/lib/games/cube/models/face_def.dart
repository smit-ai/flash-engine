import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class FaceDef {
  final String id;
  final Vector3 baseNormal;
  final Matrix4 baseTransform;
  late Color displayColor;
  double? zDepth;

  FaceDef(this.id, this.baseNormal, this.baseTransform);
}
