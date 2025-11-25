import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' as foundation;

enum BackoffState {
  stopped,
  running,
  executingCallback,
}

class Backoff {
  Backoff(
    this.callback, {
    this.interval = const Duration(seconds: 10),
    this.maxInterval = const Duration(minutes: 5),
    this.continuous = false,
    this.showLogs = false,
  });

  final Future<void> Function() callback;
  final Duration interval;
  final Duration maxInterval;
  final bool continuous;
  final bool showLogs;

  Timer? _timer;
  late Duration _currentInterval;
  final foundation.ValueNotifier<BackoffState> state = foundation.ValueNotifier(BackoffState.stopped);

  void log(String message) {
    if (showLogs) {
      developer.log(message, name: 'Backoff');
    }
  }

  void start() {
    if (_timer != null) {
      log("Backoff is already running.");
      return;
    }

    _currentInterval = interval;
    state.value = BackoffState.running;
    log("Backoff started with initial interval: $interval");
    _scheduleNext();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state.value = BackoffState.stopped;
    state.dispose();
    log("Backoff stopped.");
  }

  void _scheduleNext() {
    log("Scheduling next attempt in: $_currentInterval");

    _timer = Timer(_currentInterval, () async {
      if (continuous && state.value == BackoffState.executingCallback) {
        log("Skipping execution: Previous callback is still running.");
        return;
      }

      state.value = BackoffState.executingCallback;

      try {
        await callback();
        _currentInterval = interval;
        log("Backoff callback successful.");
      } catch (ex) {
        log("Backoff callback failed: $ex");

        // Exponential Backoff
        _currentInterval = Duration(
          milliseconds: (_currentInterval.inMilliseconds * 2).clamp(interval.inMilliseconds, maxInterval.inMilliseconds),
        );
      } finally {
        state.value = BackoffState.running;

        if (continuous || _currentInterval > interval) {
          _scheduleNext();
        } else {
          stop();
        }
      }
    });
  }
}
