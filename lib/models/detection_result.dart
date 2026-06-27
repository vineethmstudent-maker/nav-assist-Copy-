enum ObstacleLabel {
  person,
  group_of_people,
  child,
  animal,
  chair,
  table,
  sofa,
  desk,
  bed,
  door_open,
  door_closed,
  stairs_up,
  stairs_down,
  step_up,
  step_down,
  wall,
  pillar,
  glass_door,
  vehicle,
  bicycle,
  shopping_cart,
  trolley,
  wet_floor,
  narrow_passage,
  counter,
  shelf,
  clear,
  unknown,
}

enum ObstaclePosition { left, center, right, unclear }
enum CueSource { safety, sensor, gate, gemini }

class EnvironmentInfo {
  final String setting;
  final String crowding;
  final String lighting;
  final bool   floorHazards;
  final bool   narrowPassage;

  const EnvironmentInfo({
    required this.setting,
    required this.crowding,
    required this.lighting,
    required this.floorHazards,
    required this.narrowPassage,
  });

  factory EnvironmentInfo.empty() => const EnvironmentInfo(
    setting:       'unknown',
    crowding:      'unknown',
    lighting:      'unknown',
    floorHazards:  false,
    narrowPassage: false,
  );

  bool get isCrowded => crowding == 'crowded' || crowding == 'moderate';
  bool get isDark    => lighting == 'dark' || lighting == 'dim';
}

class SecondaryObstacle {
  final String type;
  final String position;
  final String distanceEstimate;

  const SecondaryObstacle({
    required this.type,
    required this.position,
    required this.distanceEstimate,
  });
}

class GateResult {
  final bool   obstacleDetected;
  final double confidence;
  final int    latencyMs;

  const GateResult({
    required this.obstacleDetected,
    required this.confidence,
    required this.latencyMs,
  });

  factory GateResult.error() => const GateResult(
    obstacleDetected: true,
    confidence:       0.0,
    latencyMs:        0,
  );
}

class DetectionResult {
  final ObstacleLabel    label;
  final String           specifics;
  final ObstaclePosition position;
  final String           distanceEstimate;
  final bool             isMoving;
  final String           movingDirection;
  final List<SecondaryObstacle> secondaryObstacles;
  final EnvironmentInfo  environment;
  final String           navigationInstruction;
  final String           urgency;
  final double           confidence;
  final String           uncertaintyReason;
  final int              latencyMs;
  final bool             success;
  final String           rawResponse;

  const DetectionResult({
    required this.label,
    required this.specifics,
    required this.position,
    required this.distanceEstimate,
    required this.isMoving,
    required this.movingDirection,
    required this.secondaryObstacles,
    required this.environment,
    required this.navigationInstruction,
    required this.urgency,
    required this.confidence,
    required this.uncertaintyReason,
    required this.latencyMs,
    required this.success,
    required this.rawResponse,
  });

  factory DetectionResult.fallback(String reason) => DetectionResult(
    label:                 ObstacleLabel.unknown,
    specifics:             '',
    position:              ObstaclePosition.unclear,
    distanceEstimate:      'unknown',
    isMoving:              false,
    movingDirection:       '',
    secondaryObstacles:    const [],
    environment:           EnvironmentInfo.empty(),
    navigationInstruction: '',
    urgency:               'medium',
    confidence:            0.0,
    uncertaintyReason:     reason,
    latencyMs:             0,
    success:               false,
    rawResponse:           '',
  );

  String get labelDisplay =>
      label.name.replaceAll('_', ' ').toUpperCase();

  bool get isCritical => urgency == 'critical';
  bool get isHigh     => urgency == 'high' || urgency == 'critical';
}

class NavCue {
  final String          text;
  final CueSource       source;
  final String          direction;
  final String          obstacleLabel;
  final EnvironmentInfo environment;
  final String          urgency;
  final DateTime        timestamp;
  final int             totalLatencyMs;
  final String?         sceneDescription;
  final String?         sceneTrigger;

  const NavCue({
    required this.text,
    required this.source,
    required this.direction,
    required this.obstacleLabel,
    required this.environment,
    required this.urgency,
    required this.timestamp,
    required this.totalLatencyMs,
    this.sceneDescription,
    this.sceneTrigger,
  });
}
