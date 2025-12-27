import 'package:flutter/widgets.dart';
import '../graph/node.dart';

class FLightNode extends FNode {
  Color color;
  double intensity;

  FLightNode({super.name = 'Light', this.color = const Color(0xFFFFFFFF), this.intensity = 1.0});
}
