import 'package:flutter/foundation.dart';

/// Score and combo system for arcade-style games.
///
/// Features:
/// - Score tracking with multiplier
/// - Combo system with timeout
/// - High score persistence
/// - Score milestones
///
/// Example:
/// ```dart
/// final score = FScoreSystem(comboTimeout: Duration(seconds: 2));
/// score.add(10); // +10 points
/// score.add(10); // +20 points (2x combo)
/// score.add(10); // +30 points (3x combo)
/// // After 2 seconds without scoring...
/// score.add(10); // +10 points (combo reset)
/// ```
class FScoreSystem extends ChangeNotifier {
  /// Current score
  int _score = 0;
  int get score => _score;

  /// High score
  int _highScore = 0;
  int get highScore => _highScore;

  /// Current combo count
  int _comboCount = 0;
  int get comboCount => _comboCount;

  /// Combo multiplier (1.0 = no bonus)
  double get comboMultiplier => 1.0 + (_comboCount * 0.5).clamp(0.0, 9.0);

  /// Maximum combo multiplier
  final double maxMultiplier;

  /// Time window for combo continuation
  final Duration comboTimeout;

  /// Last score time
  DateTime? _lastScoreTime;

  /// Milestone thresholds (for bonus events)
  final List<int> milestones;
  int _lastMilestoneIndex = -1;

  /// Callback when milestone is reached
  void Function(int milestone)? onMilestone;

  FScoreSystem({
    this.comboTimeout = const Duration(seconds: 2),
    this.maxMultiplier = 10.0,
    this.milestones = const [100, 250, 500, 1000, 2500, 5000, 10000],
    this.onMilestone,
  });

  /// Add score with combo multiplier
  int add(int points) {
    final now = DateTime.now();

    // Check combo timeout
    if (_lastScoreTime != null) {
      final elapsed = now.difference(_lastScoreTime!);
      if (elapsed > comboTimeout) {
        _comboCount = 0;
      }
    }

    // Increment combo
    _comboCount++;
    _lastScoreTime = now;

    // Apply multiplier
    final multipliedPoints = (points * comboMultiplier).round();
    _score += multipliedPoints;

    // Check milestones
    _checkMilestones();

    // Update high score
    if (_score > _highScore) {
      _highScore = _score;
    }

    notifyListeners();
    return multipliedPoints;
  }

  /// Add score without combo (flat points)
  void addFlat(int points) {
    _score += points;
    if (_score > _highScore) {
      _highScore = _score;
    }
    _checkMilestones();
    notifyListeners();
  }

  void _checkMilestones() {
    for (int i = _lastMilestoneIndex + 1; i < milestones.length; i++) {
      if (_score >= milestones[i]) {
        _lastMilestoneIndex = i;
        onMilestone?.call(milestones[i]);
      }
    }
  }

  /// Reset combo (e.g., on miss)
  void breakCombo() {
    _comboCount = 0;
    notifyListeners();
  }

  /// Reset score (new game)
  void reset() {
    _score = 0;
    _comboCount = 0;
    _lastScoreTime = null;
    _lastMilestoneIndex = -1;
    notifyListeners();
  }

  /// Check if combo is active
  bool get isComboActive {
    if (_lastScoreTime == null) return false;
    return DateTime.now().difference(_lastScoreTime!) < comboTimeout;
  }

  /// Time remaining in combo window
  Duration get comboTimeRemaining {
    if (_lastScoreTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastScoreTime!);
    final remaining = comboTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
