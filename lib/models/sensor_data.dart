import '../config.dart';

class SensorData {
  final double left;
  final double center;
  final double right;
  final DateTime timestamp;

  const SensorData({
    required this.left,
    required this.center,
    required this.right,
    required this.timestamp,
  });

  factory SensorData.fromSerial(String line) {
    try {
      final parts = line.trim().split(',');
      if (parts.length != 3) throw const FormatException('Need 3 values');
      return SensorData(
        left:      double.parse(parts[0].trim()),
        center:    double.parse(parts[1].trim()),
        right:     double.parse(parts[2].trim()),
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return SensorData(
        left: 400, center: 400, right: 400,
        timestamp: DateTime.now(),
      );
    }
  }

  factory SensorData.empty() => SensorData(
    left: 400, center: 400, right: 400,
    timestamp: DateTime.now(),
  );

  String get closestDirection {
    if (left <= center && left <= right) return 'left';
    if (right <= center) return 'right';
    return 'center';
  }

  String get safeDirection {
    if (left > right + 30) return 'move left';
    if (right > left + 30) return 'move right';
    if (center < AppConfig.dangerDistance) return 'stop and wait';
    return 'proceed with caution';
  }

  bool get isCritical => center < AppConfig.criticalDistance;
  bool get isDanger =>
      center < AppConfig.dangerDistance ||
      left   < AppConfig.dangerDistance ||
      right  < AppConfig.dangerDistance;
  bool get isCaution => center < AppConfig.cautionDistance;

  double get minimumDistance =>
      [left, center, right].reduce((a, b) => a < b ? a : b);

  double barValue(double distance) =>
      (1.0 - (distance / 200.0)).clamp(0.0, 1.0);

  double get leftBar   => barValue(left);
  double get centerBar => barValue(center);
  double get rightBar  => barValue(right);
}

/// Tracks velocity of obstacles using rolling history of SensorData.
/// Used to detect moving people/pets and estimate approach speed.
class VelocityTracker {
  final List<SensorData> _history = [];
  final int maxHistory;

  VelocityTracker({this.maxHistory = 5});

  void add(SensorData data) {
    _history.add(data);
    if (_history.length > maxHistory) _history.removeAt(0);
  }

  /// cm/s — positive means obstacle getting closer, negative means moving away
  double get centerVelocity {
    if (_history.length < 2) return 0.0;
    final oldest = _history.first;
    final newest = _history.last;
    final dt = newest.timestamp.difference(oldest.timestamp).inMilliseconds;
    if (dt <= 0) return 0.0;
    // Positive = obstacle approaching (distance decreasing)
    return (oldest.center - newest.center) / (dt / 1000.0);
  }

  double get leftVelocity {
    if (_history.length < 2) return 0.0;
    final oldest = _history.first;
    final newest = _history.last;
    final dt = newest.timestamp.difference(oldest.timestamp).inMilliseconds;
    if (dt <= 0) return 0.0;
    return (oldest.left - newest.left) / (dt / 1000.0);
  }

  double get rightVelocity {
    if (_history.length < 2) return 0.0;
    final oldest = _history.first;
    final newest = _history.last;
    final dt = newest.timestamp.difference(oldest.timestamp).inMilliseconds;
    if (dt <= 0) return 0.0;
    return (oldest.right - newest.right) / (dt / 1000.0);
  }

  bool get isApproaching =>
      centerVelocity > AppConfig.movingVelocityThreshold;

  bool get isReceding =>
      centerVelocity < -AppConfig.movingVelocityThreshold;

  bool get isMoving =>
      centerVelocity.abs() > AppConfig.movingVelocityThreshold;

  String get approachDescription {
    final v = centerVelocity;
    if (v > 60)  return 'moving toward you quickly';
    if (v > 25)  return 'moving toward you';
    if (v > 10)  return 'moving slowly toward you';
    if (v < -40) return 'moving away quickly';
    if (v < -10) return 'moving away from you';
    return 'stationary';
  }

  void clear() => _history.clear();
}


