import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class SceneManagerDemoExample extends StatefulWidget {
  const SceneManagerDemoExample({super.key});

  @override
  State<SceneManagerDemoExample> createState() => _SceneManagerDemoExampleState();
}

class _SceneManagerDemoExampleState extends State<SceneManagerDemoExample> {
  late FlashSceneManager _sceneManager;
  SceneTransition _selectedTransition = SceneTransition.fade;

  final List<SceneTransition> _transitions = [
    SceneTransition.fade,
    SceneTransition.slideLeft,
    SceneTransition.slideRight,
    SceneTransition.slideUp,
    SceneTransition.slideDown,
    SceneTransition.scale,
    SceneTransition.rotate,
  ];

  @override
  void initState() {
    super.initState();
    _sceneManager = FlashSceneManager();

    // Register scenes
    _sceneManager.registerScene(
      FlashSceneWrapper(
        name: 'menu',
        onEnter: () => debugPrint('Menu entered'),
        onExit: () => debugPrint('Menu exited'),
      ),
    );

    _sceneManager.registerScene(
      FlashSceneWrapper(
        name: 'game',
        onEnter: () => debugPrint('Game entered'),
        onExit: () => debugPrint('Game exited'),
      ),
    );

    _sceneManager.registerScene(
      FlashSceneWrapper(
        name: 'settings',
        onEnter: () => debugPrint('Settings entered'),
        onExit: () => debugPrint('Settings exited'),
      ),
    );

    // Start at menu
    _sceneManager.goTo('menu', transition: SceneTransition.none);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      appBar: AppBar(title: const Text('Scene Manager Demo'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Flash(
        child: Builder(
          builder: (context) {
            final engineWidget = context.dependOnInheritedWidgetOfExactType<InheritedFlashNode>();
            final engine = engineWidget?.engine;

            if (engine != null) {
              engine.onUpdate = () {
                final dt = 1 / 60.0;
                _sceneManager.update(dt);
                setState(() {});
              };
            }

            return Stack(
              children: [
                // Camera
                FlashCameraWidget(position: v.Vector3(0, 0, 500), fov: 60),

                // Scene content with transitions
                FlashSceneTransitionWidget(
                  sceneManager: _sceneManager,
                  builder: (scene) => _buildSceneContent(scene.name),
                ),

                // Transition selector
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
                        // Current scene indicator
                        Text(
                          '📍 Current: ${_sceneManager.currentScene?.name ?? "none"}',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Transition selector
                        const Text('🎭 Transition:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 35,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _transitions.map((t) {
                              final isSelected = _selectedTransition == t;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTransition = t),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.greenAccent : Colors.white24,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      t.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Scene buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSceneButton('menu', Icons.home, Colors.blueAccent),
                            _buildSceneButton('game', Icons.games, Colors.orangeAccent),
                            _buildSceneButton('settings', Icons.settings, Colors.purpleAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSceneButton(String sceneName, IconData icon, Color color) {
    final isActive = _sceneManager.currentScene?.name == sceneName;
    return GestureDetector(
      onTap: () {
        if (!isActive && !_sceneManager.isTransitioning) {
          _sceneManager.goTo(sceneName, transition: _selectedTransition, duration: 0.5);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 28),
            const SizedBox(height: 4),
            Text(
              sceneName.toUpperCase(),
              style: TextStyle(color: isActive ? Colors.white : color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneContent(String sceneName) {
    switch (sceneName) {
      case 'menu':
        return _buildMenuScene();
      case 'game':
        return _buildGameScene();
      case 'settings':
        return _buildSettingsScene();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMenuScene() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, color: Colors.white, size: 60),
            SizedBox(height: 16),
            Text(
              'MENU',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Welcome to Flash Engine!', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScene() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade900, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.games, color: Colors.white, size: 60),
            SizedBox(height: 16),
            Text(
              'GAME',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Your game content here!', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScene() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, color: Colors.white, size: 60),
            SizedBox(height: 16),
            Text(
              'SETTINGS',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Configure your preferences', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
