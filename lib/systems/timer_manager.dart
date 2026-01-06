import 'dart:async';

/// Centralized timer manager to prevent timer accumulation and message queue flooding.
///
/// Key issues this solves:
/// 1. Orphaned timers that continue firing after widgets are disposed
/// 2. Multiple identical timers stacking up
/// 3. Uncontrolled periodic timers flooding the message queue
///
/// Usage:
/// ```dart
/// // In StatefulWidget:
/// late final String _timerGroupId;
///
/// @override
/// void initState() {
///   super.initState();
///   _timerGroupId = TimerManager.instance.createGroup('MyWidget');
/// }
///
/// void someMethod() {
///   TimerManager.instance.setTimeout(
///     group: _timerGroupId,
///     id: 'myAction',
///     duration: Duration(milliseconds: 500),
///     callback: () => doSomething(),
///   );
/// }
///
/// @override
/// void dispose() {
///   TimerManager.instance.cancelGroup(_timerGroupId);
///   super.dispose();
/// }
/// ```
class TimerManager {
  /// Singleton instance
  static final TimerManager _instance = TimerManager._internal();
  static TimerManager get instance => _instance;
  factory TimerManager() => _instance;
  TimerManager._internal();

  // Timer groups: groupId -> (timerId -> timer)
  final Map<String, Map<String, Timer>> _timerGroups = {};

  // Periodic timers with controlled tick rates
  final Map<String, _ManagedPeriodicTimer> _periodicTimers = {};

  // Counter for generating unique group IDs
  int _groupCounter = 0;

  // Tracking for diagnostics
  int _timersCreated = 0;
  int _timersCancelled = 0;
  int _callbacksExecuted = 0;

  /// Create a new timer group and return its ID.
  /// Groups should be created per widget/component.
  String createGroup(String name) {
    final id = '${name}_${_groupCounter++}';
    _timerGroups[id] = {};
    return id;
  }

  /// Set a one-shot timer.
  ///
  /// If a timer with the same ID already exists in the group, it is cancelled
  /// first. This prevents timer stacking.
  void setTimeout({
    required String group,
    required String id,
    required Duration duration,
    required void Function() callback,
  }) {
    // Ensure group exists
    _timerGroups.putIfAbsent(group, () => {});

    // Cancel existing timer with same ID
    _timerGroups[group]?[id]?.cancel();

    _timersCreated++;

    // Create new timer
    _timerGroups[group]?[id] = Timer(duration, () {
      _callbacksExecuted++;
      // Remove from tracking after execution
      _timerGroups[group]?.remove(id);
      callback();
    });
  }

  /// Set a delayed callback that can be easily cancelled.
  /// Returns a cancel function.
  void Function() setDelayed({
    required String group,
    required Duration duration,
    required void Function() callback,
  }) {
    final id = 'delayed_${DateTime.now().microsecondsSinceEpoch}';
    setTimeout(group: group, id: id, duration: duration, callback: callback);

    return () {
      cancelTimer(group: group, id: id);
    };
  }

  /// Cancel a specific timer.
  void cancelTimer({required String group, required String id}) {
    _timerGroups[group]?[id]?.cancel();
    _timerGroups[group]?.remove(id);
    _timersCancelled++;
  }

  /// Cancel all timers in a group.
  void cancelGroup(String group) {
    final timers = _timerGroups.remove(group);
    if (timers != null) {
      for (final timer in timers.values) {
        timer.cancel();
        _timersCancelled++;
      }
    }

    // Also cancel any periodic timers with this group prefix
    final periodicToRemove = <String>[];
    for (final key in _periodicTimers.keys) {
      if (key.startsWith('$group:')) {
        _periodicTimers[key]?.cancel();
        periodicToRemove.add(key);
      }
    }
    for (final key in periodicToRemove) {
      _periodicTimers.remove(key);
    }
  }

  /// Cancel all timers globally. Use for app pause/reset.
  void cancelAll() {
    for (final group in _timerGroups.values) {
      for (final timer in group.values) {
        timer.cancel();
        _timersCancelled++;
      }
    }
    _timerGroups.clear();

    for (final periodic in _periodicTimers.values) {
      periodic.cancel();
    }
    _periodicTimers.clear();
  }

  /// Create a managed periodic timer with controlled tick rate.
  ///
  /// Unlike raw Timer.periodic, this:
  /// - Has a maximum tick rate to prevent queue flooding
  /// - Can be paused/resumed
  /// - Auto-cleans up orphaned timers
  /// - Skips ticks if the previous callback is still running
  void setPeriodicTimer({
    required String group,
    required String id,
    required Duration period,
    required void Function() callback,
    Duration? minInterval,
  }) {
    final key = '$group:$id';

    // Cancel existing
    _periodicTimers[key]?.cancel();

    final managedTimer = _ManagedPeriodicTimer(
      period: period,
      callback: () {
        _callbacksExecuted++;
        callback();
      },
      minInterval:
          minInterval ?? const Duration(milliseconds: 16), // ~60fps max
    );

    _periodicTimers[key] = managedTimer;
    _timersCreated++;
  }

  /// Pause a periodic timer.
  void pausePeriodic({required String group, required String id}) {
    _periodicTimers['$group:$id']?.pause();
  }

  /// Resume a periodic timer.
  void resumePeriodic({required String group, required String id}) {
    _periodicTimers['$group:$id']?.resume();
  }

  /// Cancel a periodic timer.
  void cancelPeriodic({required String group, required String id}) {
    final key = '$group:$id';
    _periodicTimers[key]?.cancel();
    _periodicTimers.remove(key);
    _timersCancelled++;
  }

  /// Get diagnostic statistics.
  Map<String, dynamic> getStats() {
    int activeTimers = 0;
    for (final group in _timerGroups.values) {
      activeTimers += group.length;
    }

    return {
      'timersCreated': _timersCreated,
      'timersCancelled': _timersCancelled,
      'callbacksExecuted': _callbacksExecuted,
      'activeTimers': activeTimers,
      'activePeriodicTimers': _periodicTimers.length,
      'groups': _timerGroups.keys.toList(),
    };
  }

  /// Print diagnostic report.
  void printDiagnostics() {
    final stats = getStats();
    print('\n========== TIMER MANAGER DIAGNOSTICS ==========');
    print('Timers Created: ${stats['timersCreated']}');
    print('Timers Cancelled: ${stats['timersCancelled']}');
    print('Callbacks Executed: ${stats['callbacksExecuted']}');
    print('Active One-Shot Timers: ${stats['activeTimers']}');
    print('Active Periodic Timers: ${stats['activePeriodicTimers']}');
    print('Active Groups: ${(stats['groups'] as List).length}');
    print('================================================\n');
  }

  /// Reset all statistics.
  void resetStats() {
    _timersCreated = 0;
    _timersCancelled = 0;
    _callbacksExecuted = 0;
  }
}

/// A managed periodic timer with rate limiting and pause/resume.
class _ManagedPeriodicTimer {
  final Duration period;
  final void Function() callback;
  final Duration minInterval;

  Timer? _timer;
  bool _isPaused = false;
  bool _isRunning = false;
  DateTime _lastTick = DateTime.now();

  _ManagedPeriodicTimer({
    required this.period,
    required this.callback,
    required this.minInterval,
  }) {
    _start();
  }

  void _start() {
    _timer = Timer.periodic(period, (_) {
      if (_isPaused || _isRunning) return;

      // Rate limiting
      final now = DateTime.now();
      if (now.difference(_lastTick) < minInterval) return;

      _isRunning = true;
      _lastTick = now;

      try {
        callback();
      } finally {
        _isRunning = false;
      }
    });
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
