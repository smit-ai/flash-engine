# Flash Engine 🎮

A lightweight 2.5D game engine for Flutter with declarative widgets, physics simulation, and spatial audio.

## ✨ Features

- 🎨 **Declarative Widget API** - Build games using Flutter's familiar widget pattern
- ⚙️ **Physics Engine** - Built-in Forge2D integration with `FlashRigidBody` and `FlashStaticBody`
- 🎵 **3D Spatial Audio** - Positional audio with distance attenuation and panning
- 💡 **Real-time Lighting** - Dynamic lighting system with multiple light sources
- 📦 **Scene Graph** - Hierarchical node-based architecture
- 🎯 **Godot-inspired** - Familiar node system for game developers
- 🚀 **Performance Optimized** - Efficient rendering and physics updates

## 🎮 Widgets

### Primitives
- `FlashBox` - 2D rectangle with lighting
- `FlashSphere` - Shaded 3D sphere with texture support
- `FlashCube` - 3D cube primitive
- `FlashCircle` - 2D circle
- `FlashTriangle` - 2D triangle

### Physics
- `FlashRigidBody` - Dynamic physics body
- `FlashStaticBody` - Static/immovable body
- `FlashArea` - Trigger zones for collision detection

### Audio
- `FlashAudioPlayer` - 3D spatial audio source
- `FlashAudioController` - Programmatic audio control

### Scene
- `FlashCameraWidget` - Camera/viewport control
- `FlashLightWidget` - Point light source
- `FlashNodes` - Multi-child layout
- `FlashLabel` - Text rendering
- `FlashSprite` - Image rendering

## 🚀 Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flash:
    path: ../flash  # or publish to pub.dev
```

### Basic Example

```dart
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Flash(
          child: FlashBox(
            position: Vector3(0, 0, 0),
            width: 100,
            height: 100,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}
```

## 📚 Examples

### Physics Simulation

```dart
Flash(
  physicsWorld: FlashPhysicsWorld(gravity: -50.0),
  child: Stack(
    children: [
      // Static floor
      FlashRigidBody(
        bodyDef: BodyDef()..type = BodyType.static,
        fixtures: [FixtureDef(PolygonShape()..setAsBoxXY(200, 10))],
        child: FlashBox(width: 400, height: 20, color: Colors.grey),
      ),
      // Falling box
      FlashRigidBody(
        position: Vector3(0, 100, 0),
        fixtures: [FixtureDef(PolygonShape()..setAsBoxXY(10, 10))..density = 1.0],
        child: FlashBox(width: 20, height: 20, color: Colors.red),
      ),
    ],
  ),
)
```

### 3D Audio

```dart
FlashAudioPlayer(
  assetPath: 'asset/sound.mp3',
  is3D: true,
  minDistance: 50,
  maxDistance: 1000,
  autoplay: true,
)
```

### Dynamic Lighting

```dart
Stack(
  children: [
    FlashLightWidget(
      position: Vector3(0, 0, 500),
      color: Colors.white,
      intensity: 1.0,
    ),
    FlashSphere(
      radius: 80,
      color: Colors.blue,
      position: Vector3(0, 0, 0),
    ),
  ],
)
```

## 🏗️ Architecture

```
┌─────────────────────────────┐
│     Flutter Widgets         │
│  (FlashBox, FlashSphere...) │
└──────────┬──────────────────┘
           │
┌──────────▼──────────────────┐
│    FlashNodeWidget          │
│   (Widget → Node Bridge)    │
└──────────┬──────────────────┘
           │
┌──────────▼──────────────────┐
│      FlashNode              │
│   (Scene Graph Node)        │
└──────────┬──────────────────┘
           │
┌──────────▼──────────────────┐
│     FlashEngine             │
│  • Scene Update Loop        │
│  • Physics Integration      │
│  • Audio System             │
│  • Camera Management        │
└─────────────────────────────┘
```

## 🎯 Core Concepts

### Scene Graph
All visual elements inherit from `FlashNode` and form a hierarchical tree. Transformations propagate down the tree.

### Physics Bodies
`FlashRigidBody` defaults to **dynamic** (moves with physics).  
`FlashStaticBody` is immovable (floors, walls).

### Audio System
- **2D Audio**: Simple playback
- **3D Audio**: Position-based with distance attenuation

### Rendering Loop
Engine runs at 60 FPS, updating physics and scene graph automatically.

## 🔧 Performance Tips

1. **Use `FlashNodes`** for multiple children instead of nested `Stack`
2. **Cache default camera** - Already optimized in engine
3. **Limit physics bodies** - Complex shapes are expensive
4. **Use `autoplay: false`** for on-demand audio

## 📁 Project Structure

```
lib/
├── src/
│   ├── core/           # Core engine systems
│   │   ├── graph/      # Scene graph (FlashNode, FlashScene)
│   │   ├── rendering/  # Camera, lighting, painter
│   │   └── systems/    # Engine, physics, audio
│   └── widgets/        # Declarative widgets
│       ├── primitives/ # FlashBox, FlashSphere...
│       ├── physics/    # FlashRigidBody...
│       ├── audio/      # FlashAudioPlayer
│       └── ui/         # FlashLabel, FlashSprite
demo/                   # Example games/demos
```

## 🤝 Contributing

Contributions welcome! This is an experimental engine for learning and prototyping.

## 📄 License

MIT License - See LICENSE file

## 🙏 Credits

- **Physics**: [Forge2D](https://pub.dev/packages/forge2d)
- **Audio**: [flutter_soloud](https://pub.dev/packages/flutter_soloud)
- **Inspiration**: Godot Engine

---

Built with ❤️ using Flutter and Dart
