import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Helper class for performance testing and monitoring
class PerformanceTestHelper {
  static final PerformanceTestHelper _instance =
      PerformanceTestHelper._internal();

  factory PerformanceTestHelper() => _instance;

  PerformanceTestHelper._internal();

  // Frame timing tracking
  final List<Duration> _frameDurations = [];
  bool _isTracking = false;

  /// Start tracking frame performance
  void startFrameTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _frameDurations.clear();

    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  /// Stop tracking frame performance
  void stopFrameTracking() {
    _isTracking = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
  }

  /// Callback for frame timing
  void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isTracking) return;

    for (final timing in timings) {
      _frameDurations.add(timing.totalSpan);
    }
  }

  /// Get average frame time in milliseconds
  double getAverageFrameTime() {
    if (_frameDurations.isEmpty) return 0.0;

    final total = _frameDurations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );

    return total / _frameDurations.length / 1000; // Convert to milliseconds
  }

  /// Get frames per second (FPS)
  double getFPS() {
    final avgFrameTime = getAverageFrameTime();
    if (avgFrameTime == 0) return 0.0;

    return 1000 / avgFrameTime; // FPS = 1000ms / avg frame time
  }

  /// Get percentage of frames that dropped (below 60fps)
  double getDroppedFramePercentage() {
    if (_frameDurations.isEmpty) return 0.0;

    const targetFrameTime = Duration(microseconds: 16667); // ~60fps

    final droppedFrames = _frameDurations
        .where((duration) => duration > targetFrameTime)
        .length;

    return (droppedFrames / _frameDurations.length) * 100;
  }

  /// Get the worst frame time in milliseconds
  double getWorstFrameTime() {
    if (_frameDurations.isEmpty) return 0.0;

    final worst = _frameDurations.reduce((a, b) => a > b ? a : b);

    return worst.inMicroseconds / 1000;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'averageFrameTime': getAverageFrameTime(),
      'fps': getFPS(),
      'droppedFramePercentage': getDroppedFramePercentage(),
      'worstFrameTime': getWorstFrameTime(),
      'totalFrames': _frameDurations.length,
    };
  }

  /// Print performance report to console
  void printPerformanceReport() {
    final report = getPerformanceReport();

    debugPrint('=== Performance Report ===');
    debugPrint(
      'Average Frame Time: ${report['averageFrameTime'].toStringAsFixed(2)}ms',
    );
    debugPrint('FPS: ${report['fps'].toStringAsFixed(2)}');
    debugPrint(
      'Dropped Frames: ${report['droppedFramePercentage'].toStringAsFixed(2)}%',
    );
    debugPrint(
      'Worst Frame Time: ${report['worstFrameTime'].toStringAsFixed(2)}ms',
    );
    debugPrint('Total Frames: ${report['totalFrames']}');
    debugPrint('========================');
  }

  /// Reset tracking data
  void reset() {
    _frameDurations.clear();
  }

  /// Check if performance is good (>= 55 FPS, < 10% dropped frames)
  bool isPerformanceGood() {
    final fps = getFPS();
    final droppedPercentage = getDroppedFramePercentage();

    return fps >= 55 && droppedPercentage < 10;
  }

  /// Measure performance of a specific operation
  static Future<Duration> measureOperation(
    Future<void> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measure build time of a widget
  static Duration measureBuildTime(void Function() buildFunction) {
    final stopwatch = Stopwatch()..start();
    buildFunction();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
}

/// Extension for easy performance monitoring
extension PerformanceMonitoring on Future<void> {
  /// Execute with performance monitoring
  Future<Duration> withPerformanceMonitoring() async {
    return PerformanceTestHelper.measureOperation(() => this);
  }
}
