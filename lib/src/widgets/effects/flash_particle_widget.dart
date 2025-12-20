import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../../core/systems/particle.dart';
import '../framework.dart';

/// Declarative widget for particle effects
class FlashParticleWidget extends FlashNodeWidget {
  final ParticleEmitterConfig? config;
  final bool emitting;
  final v.Vector3? initialPosition;

  // Can't be const because ParticleEmitterConfig constructor isn't const
  const FlashParticleWidget({super.key, this.config, this.emitting = true, this.initialPosition, super.child});

  @override
  State<FlashParticleWidget> createState() => _FlashParticleWidgetState();
}

class _FlashParticleWidgetState extends FlashNodeWidgetState<FlashParticleWidget, FlashParticleEmitter> {
  @override
  FlashParticleEmitter createNode() {
    final emitter = FlashParticleEmitter(config: widget.config ?? ParticleEmitterConfig(), emitting: widget.emitting);
    if (widget.initialPosition != null) {
      emitter.transform.position = widget.initialPosition!;
    }
    return emitter;
  }

  @override
  void applyProperties([FlashParticleWidget? oldWidget]) {
    super.applyProperties(oldWidget);
    if (widget.config != null) {
      node.config = widget.config!;
    }
    node.emitting = widget.emitting;
  }
}

/// Fire effect preset widget
class FlashFire extends StatelessWidget {
  final v.Vector3 position;
  final double scale;

  const FlashFire({super.key, required this.position, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return FlashParticleWidget(
      initialPosition: position,
      config: ParticleEmitterConfig(
        emissionRate: 80 * scale,
        lifetimeMin: 0.3,
        lifetimeMax: 1.0,
        velocityMin: v.Vector3(-20 * scale, 80 * scale, 0),
        velocityMax: v.Vector3(20 * scale, 150 * scale, 0),
        gravity: v.Vector3(0, 50, 0),
        sizeMin: 8 * scale,
        sizeMax: 20 * scale,
        startColor: const Color(0xFFFFDD00),
        endColor: const Color(0x00FF4400),
        spreadAngle: 0.3,
      ),
    );
  }
}

/// Smoke effect preset widget
class FlashSmoke extends StatelessWidget {
  final v.Vector3 position;
  final double scale;

  const FlashSmoke({super.key, required this.position, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return FlashParticleWidget(
      initialPosition: position,
      config: ParticleEmitterConfig(
        emissionRate: 30 * scale,
        lifetimeMin: 1.0,
        lifetimeMax: 3.0,
        velocityMin: v.Vector3(-10 * scale, 30 * scale, 0),
        velocityMax: v.Vector3(10 * scale, 60 * scale, 0),
        gravity: v.Vector3(0, 20, 0),
        sizeMin: 15 * scale,
        sizeMax: 40 * scale,
        startColor: const Color(0xAA666666),
        endColor: const Color(0x00333333),
        spreadAngle: 0.4,
      ),
    );
  }
}

/// Sparkle effect preset widget
class FlashSparkle extends StatelessWidget {
  final v.Vector3 position;
  final double scale;

  const FlashSparkle({super.key, required this.position, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return FlashParticleWidget(
      initialPosition: position,
      config: ParticleEmitterConfig(
        emissionRate: 100 * scale,
        lifetimeMin: 0.2,
        lifetimeMax: 0.8,
        velocityMin: v.Vector3(-100 * scale, -100 * scale, -50 * scale),
        velocityMax: v.Vector3(100 * scale, 100 * scale, 50 * scale),
        gravity: v.Vector3.zero(),
        sizeMin: 2 * scale,
        sizeMax: 6 * scale,
        startColor: const Color(0xFFFFFFFF),
        endColor: const Color(0x00FFFF00),
        spreadAngle: 3.14,
        rotationSpeedMin: -5,
        rotationSpeedMax: 5,
      ),
    );
  }
}
