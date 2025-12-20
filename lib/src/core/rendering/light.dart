import 'package:flutter/widgets.dart';
import '../graph/node.dart';

class FlashLightNode extends FlashNode {
  Color color;
  double intensity;

  FlashLightNode({super.name = 'FlashLight', this.color = const Color(0xFFFFFFFF), this.intensity = 1.0});
}
