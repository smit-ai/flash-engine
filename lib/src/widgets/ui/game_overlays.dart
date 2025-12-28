import 'package:flutter/material.dart';

/// Game over overlay with score display and actions.
///
/// Example:
/// ```dart
/// FGameOverOverlay(
///   title: 'GAME OVER',
///   score: 1250,
///   highScore: 2000,
///   onRestart: () => restartGame(),
///   onExit: () => Navigator.pop(context),
/// )
/// ```
class FGameOverOverlay extends StatelessWidget {
  /// Title text
  final String title;

  /// Current score
  final int score;

  /// High score
  final int highScore;

  /// Callback for restart button
  final VoidCallback onRestart;

  /// Callback for exit button
  final VoidCallback onExit;

  /// Restart button text
  final String restartText;

  /// Exit button text
  final String exitText;

  /// Background color
  final Color backgroundColor;

  /// Accent color for new high score
  final Color accentColor;

  const FGameOverOverlay({
    super.key,
    this.title = 'GAME OVER',
    required this.score,
    required this.highScore,
    required this.onRestart,
    required this.onExit,
    this.restartText = 'Play Again',
    this.exitText = 'Exit',
    this.backgroundColor = Colors.black54,
    this.accentColor = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = score >= highScore && score > 0;

    return Container(
      color: backgroundColor,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade900, Colors.grey.shade800],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isNewHighScore ? accentColor : Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: (isNewHighScore ? accentColor : Colors.black).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  shadows: [Shadow(color: isNewHighScore ? accentColor : Colors.cyanAccent, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 24),
              if (isNewHighScore) ...[
                Icon(Icons.emoji_events, color: accentColor, size: 48),
                const SizedBox(height: 8),
                Text(
                  '🎉 NEW HIGH SCORE! 🎉',
                  style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Score: $score',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('High Score: $highScore', style: const TextStyle(color: Colors.white60, fontSize: 16)),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh),
                    label: Text(restartText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.exit_to_app),
                    label: Text(exitText),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pause overlay with resume option.
class FPauseOverlay extends StatelessWidget {
  /// Callback for resume
  final VoidCallback onResume;

  /// Callback for restart
  final VoidCallback? onRestart;

  /// Callback for exit
  final VoidCallback? onExit;

  const FPauseOverlay({super.key, required this.onResume, this.onRestart, this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_filled, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'PAUSED',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 48),
                ),
              ),
              if (onRestart != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(150, 48),
                  ),
                ),
              ],
              if (onExit != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Exit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white60),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
