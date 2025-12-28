import 'package:flutter/foundation.dart';

/// Game timer system for time-based game modes.
///
/// Features:
/// - Countdown or count-up modes
/// - Pause/resume
/// - Add/remove time
/// - Expiration callback
///
/// Example:
/// ```dart
/// final timer = FGameTimer(
///   duration: Duration(seconds: 60),
///   onExpired: () => print('Game Over!'),
/// );
/// timer.start();
/// timer.addTime(Duration(seconds: 5)); // Bonus time
/// ```
class FGameTimer extends ChangeNotifier {
  /// Initial duration
  final Duration initialDuration;

  /// Current remaining time
  Duration _remaining;
  Duration get remaining => _remaining;

  /// Whether timer counts up (stopwatch) or down (countdown)
  final bool countUp;

  /// Callback when timer expires (countdown mode)
  VoidCallback? onExpired;

  /// Callback each second tick
  void Function(Duration remaining)? onTick;

  /// Is timer running?
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Is timer expired?
  bool _isExpired = false;
  bool get isExpired => _isExpired;

  FGameTimer({this.initialDuration = const Duration(seconds: 60), this.countUp = false, this.onExpired, this.onTick})
    : _remaining = initialDuration;

  /// Start the timer
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    notifyListeners();
  }

  /// Pause the timer
  void pause() {
    _isRunning = false;
    notifyListeners();
  }

  /// Resume from pause
  void resume() {
    if (_isExpired) return;
    start();
  }

  /// Update timer (call from game loop)
  void update(Duration delta) {
    if (!_isRunning || _isExpired) return;

    if (countUp) {
      _remaining += delta;
    } else {
      _remaining -= delta;

      if (_remaining.isNegative || _remaining == Duration.zero) {
        _remaining = Duration.zero;
        _isExpired = true;
        _isRunning = false;
        onExpired?.call();
      }
    }

    onTick?.call(_remaining);
    notifyListeners();
  }

  /// Add bonus time
  void addTime(Duration bonus) {
    _remaining += bonus;
    if (_isExpired && _remaining > Duration.zero) {
      _isExpired = false;
    }
    notifyListeners();
  }

  /// Remove time (penalty)
  void removeTime(Duration penalty) {
    _remaining -= penalty;
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
    if (!countUp && _remaining == Duration.zero) {
      _isExpired = true;
      _isRunning = false;
      onExpired?.call();
    }
    notifyListeners();
  }

  /// Reset timer to initial state
  void reset() {
    _remaining = initialDuration;
    _isExpired = false;
    _isRunning = false;
    notifyListeners();
  }

  /// Get formatted time string (MM:SS)
  String get formattedTime {
    final mins = _remaining.inMinutes;
    final secs = _remaining.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Get seconds remaining
  int get secondsRemaining => _remaining.inSeconds;

  /// Progress (0.0 to 1.0) - for countdown
  double get progress {
    if (initialDuration.inMilliseconds == 0) return 0;
    return _remaining.inMilliseconds / initialDuration.inMilliseconds;
  }
}
