import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class ParticleDemoExample extends StatefulWidget {
  const ParticleDemoExample({super.key});

  @override
  State<ParticleDemoExample> createState() => _ParticleDemoExampleState();
}

class _ParticleDemoExampleState extends State<ParticleDemoExample> {
  String _selectedPreset = 'Fire';

  final Map<String, ParticleEmitterConfig> _presets = {
    'Fire': ParticleEmitterConfig.fire,
    'Smoke': ParticleEmitterConfig.smoke,
    'Sparkle': ParticleEmitterConfig.sparkle,
    'Snow': ParticleEmitterConfig.snow,
    'Rain': ParticleEmitterConfig.rain,
    'Explosion': ParticleEmitterConfig.explosion,
    'Confetti': ParticleEmitterConfig.confetti,
    'Magic': ParticleEmitterConfig.magic,
    'Bubbles': ParticleEmitterConfig.bubbles,
    'Dust': ParticleEmitterConfig.dust,
    'Fireflies': ParticleEmitterConfig.fireflies,
    'Meteor': ParticleEmitterConfig.meteor,
    'Heal': ParticleEmitterConfig.heal,
    'Electric': ParticleEmitterConfig.electric,
    'Blood': ParticleEmitterConfig.blood,
    'Lava': ParticleEmitterConfig.lava,
    'Poison': ParticleEmitterConfig.poison,
    'Steam': ParticleEmitterConfig.steam,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(title: const Text('Particle System Demo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Flash(
        child: Stack(
          children: [
            // Camera
            FlashCameraWidget(position: v.Vector3(0, 0, 500), fov: 60),

            // Particle Emitter at center
            FlashParticleWidget(
              key: ValueKey(_selectedPreset), // Force rebuild on change
              initialPosition: v.Vector3(0, -50, 0),
              config: _presets[_selectedPreset],
            ),

            // Preset selector UI
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '✨ Select Effect',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _presets.keys.map((name) {
                            final isSelected = _selectedPreset == name;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedPreset = name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orangeAccent : Colors.white24,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
