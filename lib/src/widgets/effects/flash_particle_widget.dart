import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../../core/systems/particle.dart';
import '../framework.dart';

/// Declarative widget for particle effects
class FParticles extends FNodeWidget {
  final ParticleEmitterConfig? config;
  final bool emitting;
  final v.Vector3? initialPosition;

  // Can't be const because ParticleEmitterConfig constructor isn't const
  const FParticles({super.key, this.config, this.emitting = true, this.initialPosition, super.child});

  @override
  State<FParticles> createState() => _FParticlesState();
}

class _FParticlesState extends FNodeWidgetState<FParticles, FParticleEmitter> {
  @override
  FParticleEmitter createNode() {
    final emitter = FParticleEmitter(config: widget.config ?? ParticleEmitterConfig(), emitting: widget.emitting);
    if (widget.initialPosition != null) {
      emitter.transform.position = widget.initialPosition!;
    }
    return emitter;
  }

  @override
  void applyProperties([FParticles? oldWidget]) {
    super.applyProperties(oldWidget);
    if (widget.config != null) {
      node.config = widget.config!;
    }
    node.emitting = widget.emitting;
  }
}

/// Fire effect preset widget
class FFire extends StatelessWidget {
  final v.Vector3 position;
  final double scale;

  const FFire({super.key, required this.position, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return FParticles(
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
class FSmoke extends StatelessWidget {
  final v.Vector3 position;
  final double scale;

  const FSmoke({super.key, required this.position, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return FParticles(
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
class FSparkle extends StatelessWidget {
  final v.Vector3 position;
  final double scale;

  const FSparkle({super.key, required this.position, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return FParticles(
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
