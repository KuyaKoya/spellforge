import 'dart:async';
import 'package:flutter/material.dart';

import 'timer_manager.dart';
import 'audio_manager.dart';

/// Mixin for widgets that need audio and timer management.
///
/// This mixin provides:
/// 1. Automatic timer cleanup on dispose
/// 2. Throttled setState to prevent message queue flooding
/// 3. Safe delayed callbacks that auto-cancel
/// 4. Frame-limited audio triggers
///
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   const MyScreen({super.key});
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen>
///     with GameWidgetMixin<MyScreen> {
///
///   void onButtonTap() {
///     // Audio fires immediately, UI updates are throttled
///     playSound('button_tap');
///
///     // This setState is automatically throttled
///     safeSetState(() => _counter++);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Text('Count: $_counter');
///   }
/// }
/// ```
mixin GameWidgetMixin<T extends StatefulWidget> on State<T> {
  /// Timer group for this widget instance.
  late final String _timerGroupId;

  /// Throttle tracking for setState calls.
  DateTime? _lastSetState;
  bool _setStatePending = false;
  static const int _setStateThrottleMs = 16; // ~60fps max

  /// Sequence ID for cancellable callbacks.
  int _widgetSequenceId = 0;

  @override
  void initState() {
    super.initState();
    _timerGroupId = TimerManager.instance.createGroup(
      widget.runtimeType.toString(),
    );
  }

  @override
  void dispose() {
    // Cancel all timers for this widget
    TimerManager.instance.cancelGroup(_timerGroupId);
    _widgetSequenceId++; // Invalidate any pending callbacks
    super.dispose();
  }

  /// Get a new sequence ID, invalidating previous pending callbacks.
  int startNewSequence() {
    _widgetSequenceId++;
    AudioManager.instance.clearSfxQueue();
    return _widgetSequenceId;
  }

  /// Check if a callback sequence is still valid.
  bool isSequenceValid(int sequenceId) {
    return sequenceId == _widgetSequenceId && mounted;
  }

  /// Throttled setState that limits update frequency.
  ///
  /// Prevents message queue flooding from rapid state updates.
  /// If called within 16ms of the last call, the update is coalesced.
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;

    final now = DateTime.now();

    // If we're within the throttle window and already have a pending update
    if (_lastSetState != null &&
        now.difference(_lastSetState!).inMilliseconds < _setStateThrottleMs) {
      if (_setStatePending) {
        // Skip this update, previous pending one will apply
        return;
      }

      // Schedule the update for the next frame
      _setStatePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setStatePending = false;
          _lastSetState = DateTime.now();
          setState(fn);
        }
      });
      return;
    }

    // Execute immediately
    _lastSetState = now;
    setState(fn);
  }

  /// Set a timeout that auto-cancels on dispose.
  ///
  /// [id] - Unique identifier for this timer. If a timer with the same ID
  ///        already exists, it is cancelled first.
  void setTimeout(String id, Duration duration, VoidCallback callback) {
    TimerManager.instance.setTimeout(
      group: _timerGroupId,
      id: id,
      duration: duration,
      callback: () {
        if (mounted) callback();
      },
    );
  }

  /// Set a delayed callback with sequence validation.
  ///
  /// The callback only executes if:
  /// 1. The widget is still mounted
  /// 2. The sequence ID is still valid (no new sequence started)
  Future<void> delayedAction(
    int sequenceId,
    int milliseconds,
    VoidCallback action,
  ) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    if (isSequenceValid(sequenceId) && mounted) {
      action();
    }
  }

  /// Cancel a specific timer.
  void cancelTimeout(String id) {
    TimerManager.instance.cancelTimer(group: _timerGroupId, id: id);
  }

  /// Play a sound effect with proper throttling.
  void playSound(String key) {
    AudioManager.instance.playSfx(key);
  }

  /// Play a sound effect and wait for completion.
  Future<void> playSoundAndWait(String key) async {
    await AudioManager.instance.playSfxAndWait(key);
  }
}

/// Extension on State to provide quick throttled setState.
extension ThrottledSetState<T extends StatefulWidget> on State<T> {
  /// Quick throttled setState that uses the global event system.
  ///
  /// This schedules the setState for the next frame, batching rapid updates.
  void throttledSetState(VoidCallback fn) {
    if (!mounted) return;

    // Use post-frame callback to batch updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        (this as dynamic).setState(fn);
      }
    });
  }
}

/// A controller for managing cancelable delayed operations.
///
/// Use this when you need fine-grained control over async sequences,
/// such as combat animation chains.
class SequenceController {
  int _sequenceId = 0;
  bool _disposed = false;

  /// Start a new sequence, invalidating all previous pending operations.
  int startNew() {
    _sequenceId++;
    return _sequenceId;
  }

  /// Check if a sequence is still valid.
  bool isValid(int id) {
    return !_disposed && id == _sequenceId;
  }

  /// Execute a callback only if the sequence is still valid.
  void executeIfValid(int id, VoidCallback callback) {
    if (isValid(id)) {
      callback();
    }
  }

  /// Execute an async callback after a delay, only if sequence is valid.
  Future<bool> delayedExecute(
    int id,
    Duration delay,
    VoidCallback callback,
  ) async {
    await Future.delayed(delay);
    if (isValid(id)) {
      callback();
      return true;
    }
    return false;
  }

  /// Dispose the controller, invalidating all pending operations.
  void dispose() {
    _disposed = true;
    _sequenceId++;
  }
}

/// A debouncer for limiting how often a callback can be invoked.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 300});

  /// Run the callback, cancelling any pending previous calls.
  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), callback);
  }

  /// Cancel any pending callback.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose the debouncer.
  void dispose() {
    cancel();
  }
}

/// A throttler for limiting callback frequency.
class Throttler {
  final int milliseconds;
  DateTime? _lastRun;
  Timer? _pendingTimer;

  Throttler({this.milliseconds = 100});

  /// Run the callback, throttled to the specified frequency.
  void run(VoidCallback callback) {
    final now = DateTime.now();

    if (_lastRun == null ||
        now.difference(_lastRun!).inMilliseconds >= milliseconds) {
      _lastRun = now;
      callback();
    } else if (_pendingTimer == null) {
      // Schedule for when the throttle window expires
      final remaining = milliseconds - now.difference(_lastRun!).inMilliseconds;
      _pendingTimer = Timer(Duration(milliseconds: remaining), () {
        _lastRun = DateTime.now();
        _pendingTimer = null;
        callback();
      });
    }
  }

  /// Cancel any pending callback.
  void cancel() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
  }

  /// Dispose the throttler.
  void dispose() {
    cancel();
  }
}
