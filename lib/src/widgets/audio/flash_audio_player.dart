import 'package:flutter/widgets.dart';
import '../../core/graph/audio_node.dart';
import '../framework.dart';

class FAudioController {
  _FAudioPlayerState? _state;

  void _attach(_FAudioPlayerState state) => _state = state;
  void _detach() => _state = null;

  void play() => _state?.play();
  void stop() => _state?.stop();
  bool get isPlaying => _state?.isPlaying ?? false;
}

class FAudioPlayer extends FNodeWidget {
  final String assetPath;
  final bool autoplay;
  final bool loop;
  final bool is3D;
  final double volume;
  final double minDistance;
  final double maxDistance;
  final FAudioController? controller;

  const FAudioPlayer({
    super.key,
    required this.assetPath,
    this.autoplay = true,
    this.loop = false,
    this.is3D = true,
    this.volume = 1.0,
    this.minDistance = 50.0,
    this.maxDistance = 2000.0,
    this.controller,
    super.position,
    super.name,
  });

  @override
  State<FAudioPlayer> createState() => _FAudioPlayerState();
}

class _FAudioPlayerState extends FNodeWidgetState<FAudioPlayer, FAudioNode> {
  @override
  FAudioNode createNode() => FAudioNode(
    assetPath: widget.assetPath,
    autoplay: widget.autoplay,
    loop: widget.loop,
    is3D: widget.is3D,
    volume: widget.volume,
    minDistance: widget.minDistance,
    maxDistance: widget.maxDistance,
  );

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  void play() => node.play();
  void stop() => node.stop();
  bool get isPlaying => node.isPlaying;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get engine to initialize audio node
    final engine = context.dependOnInheritedWidgetOfExactType<InheritedFNode>()?.engine;
    if (engine != null) {
      // Initialize handles waiting for system readiness
      node.initialize(engine.audio);
    }
  }
}
