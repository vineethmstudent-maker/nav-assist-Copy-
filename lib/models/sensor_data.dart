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

  /// Parse Arduino CSV line "45.2,23.1,67.8" into SensorData.
  /// Returns safe all-clear values on parse error.
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
      // Parse failed — return safe defaults (400cm = nothing detected)
      return SensorData(
        left: 400, center: 400, right: 400,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Returns safe all-clear values (used when Arduino not connected)
  factory SensorData.empty() => SensorData(
    left: 400, center: 400, right: 400,
    timestamp: DateTime.now(),
  );

  /// Which direction has the closest obstacle
  String get closestDirection {
    if (left <= center && left <= right) return 'left';
    if (right <= center) return 'right';
    return 'center';
  }

  /// Which direction is safest to move
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

  /// Normalised 0-1 value for UI bars (1 = very close, 0 = far)
  double barValue(double distance) =>
      (1.0 - (distance / 200.0)).clamp(0.0, 1.0);

  double get leftBar   => barValue(left);
  double get centerBar => barValue(center);
  double get rightBar  => barValue(right);
}
