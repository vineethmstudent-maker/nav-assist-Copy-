import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/sensor_data.dart';
import '../models/detection_result.dart';

class SceneDescriptionService {

  DateTime _lastAnyDescription   = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastProximityTrigger = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastAmbiguousTrigger = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastInconsistency    = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastStationary       = DateTime.fromMillisecondsSinceEpoch(0);

  final List<bool>   _gateHistory     = [];
  final List<double> _centerHistory   = [];
  final List<double> _leftHistory     = [];
  final List<double> _rightHistory    = [];
  final List<String> _crowdingHistory = [];

  String _lastDescription = '';
  String _lastTrigger     = '';
  bool   _isLoading       = false;

  int totalCalls         = 0;
  int proximityCount     = 0;
  int ambiguousCount     = 0;
  int inconsistencyCount = 0;
  int stationaryCount    = 0;
  int periodicCount      = 0;
  int crowdedCount       = 0;

  double proximityThreshold = 120.0;
  int    periodicSeconds    = 20;

  String get lastDescription => _lastDescription;
  String get lastTrigger     => _lastTrigger;
  bool   get isLoading       => _isLoading;

  static const String _scenePrompt = '''
You are describing an environment to a blind person who is navigating
on foot with a chest-mounted camera. Give them a complete picture of
their surroundings so they understand where they are and what is around
them.

Respond in 2-3 natural spoken sentences. Write as if you are calmly
speaking to the person directly.

Include:
- What type of space this appears to be (shop, corridor, street, office,
  home, restaurant, station, etc.)
- How busy or crowded it is and what people are doing
- Key landmarks or features that help with orientation
- Any hazards or things requiring attention
- The general feel of the space (open, narrow, busy, quiet)

Do NOT start with "I can see" or "The image shows".
Write as natural spoken English for text to speech.
''';

  String? checkTriggers({
    required SensorData       sensors,
    required GateResult?      lastGate,
    required DetectionResult? lastDetection,
  }) {
    _updateState(sensors, lastGate, lastDetection);
    final now = DateTime.now();

    if (now.difference(_lastAnyDescription).inSeconds < 4) return null;

    // TRIGGER 1: PROXIMITY
    if (sensors.center < proximityThreshold &&
        now.difference(_lastProximityTrigger).inSeconds >= 10) {
      return 'proximity';
    }

    // TRIGGER 2: AMBIGUOUS GATE
    final gateConf = lastGate?.confidence ?? 1.0;
    if (gateConf >= 0.35 && gateConf <= 0.65 &&
        now.difference(_lastAmbiguousTrigger).inSeconds >= 8) {
      return 'ambiguous';
    }

    // TRIGGER 3: DETECTION INCONSISTENCY
    if (_gateHistory.length >= 4 &&
        now.difference(_lastInconsistency).inSeconds >= 12) {
      int switches = 0;
      for (int i = 1; i < _gateHistory.length; i++) {
        if (_gateHistory[i] != _gateHistory[i - 1]) switches++;
      }
      if (switches >= 3) return 'inconsistency';
    }

    // TRIGGER 4: STATIONARY
    if (_centerHistory.length >= 4 &&
        now.difference(_lastStationary).inSeconds >= 15) {
      final cVar = _variance(_centerHistory);
      final lVar = _variance(_leftHistory);
      final rVar = _variance(_rightHistory);
      if (cVar < 25.0 && lVar < 25.0 && rVar < 25.0) {
        return 'stationary';
      }
    }

    // TRIGGER 5: CROWDED
    if (_crowdingHistory.length >= 3 &&
        now.difference(_lastAnyDescription).inSeconds >= 15) {
      final recentCrowded = _crowdingHistory
          .where((c) => c == 'crowded' || c == 'moderate')
          .length;
      if (recentCrowded >= 2) return 'crowded';
    }

    // TRIGGER 6: PERIODIC
    final allClear = sensors.center > 150 &&
                     sensors.left   > 120 &&
                     sensors.right  > 120;
    if (allClear &&
        now.difference(_lastAnyDescription).inSeconds >= periodicSeconds) {
      return 'periodic';
    }

    return null;
  }

  Future<String?> describe(
      Uint8List imageBytes, String triggerReason) async {
    if (!AppConfig.isApiKeySet) return null;

    _isLoading   = true;
    _lastTrigger = triggerReason;

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConfig.geminiEndpoint}?key=${AppConfig.geminiApiKey}'
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'contents': [{
            'parts': [
              {'text': _scenePrompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data':      base64Encode(imageBytes),
                }
              }
            ]
          }],
          'generationConfig': {
            'temperature':     0.3,
            'maxOutputTokens': 150,
            'topP':            0.9,
          },
        }),
      ).timeout(const Duration(seconds: 7));

      _isLoading = false;

      if (response.statusCode != 200) return null;

      final json       = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final text = (candidates[0]['content']['parts'][0]['text'] as String)
          .trim();

      _lastDescription    = text;
      _lastAnyDescription = DateTime.now();
      totalCalls++;
      _updateCooldown(triggerReason);

      return text;

    } catch (e) {
      _isLoading = false;
      print('[scene] describe() error: $e');
      return null;
    }
  }

  void _updateState(
      SensorData s, GateResult? g, DetectionResult? d) {
    _centerHistory.add(s.center);
    _leftHistory.add(s.left);
    _rightHistory.add(s.right);
    if (_centerHistory.length > 8) {
      _centerHistory.removeAt(0);
      _leftHistory.removeAt(0);
      _rightHistory.removeAt(0);
    }

    if (g != null) {
      _gateHistory.add(g.obstacleDetected);
      if (_gateHistory.length > 4) _gateHistory.removeAt(0);
    }

    if (d != null && d.success) {
      _crowdingHistory.add(d.environment.crowding);
      if (_crowdingHistory.length > 3) _crowdingHistory.removeAt(0);
    }
  }

  void _updateCooldown(String reason) {
    final now = DateTime.now();
    switch (reason) {
      case 'proximity':
        _lastProximityTrigger = now;
        proximityCount++;
        break;
      case 'ambiguous':
        _lastAmbiguousTrigger = now;
        ambiguousCount++;
        break;
      case 'inconsistency':
        _lastInconsistency = now;
        inconsistencyCount++;
        break;
      case 'stationary':
        _lastStationary = now;
        stationaryCount++;
        break;
      case 'crowded':
        crowdedCount++;
        break;
      case 'periodic':
        periodicCount++;
        break;
    }
  }

  double _variance(List<double> v) {
    if (v.length < 2) return 0;
    final mean = v.reduce((a, b) => a + b) / v.length;
    return v.map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) / v.length;
  }

  String triggerLabel(String reason) {
    const labels = {
      'proximity':     '📍 Obstacle approaching',
      'ambiguous':     '❓ Unclear detection',
      'inconsistency': '🔄 Scene confusion',
      'stationary':    '⏸ You stopped',
      'crowded':       '👥 Crowded environment',
      'periodic':      '👁 Ambient awareness',
    };
    return labels[reason] ?? reason;
  }

  Map<String, dynamic> toStats() => {
    'total_scene_calls':      totalCalls,
    'proximity_triggers':     proximityCount,
    'ambiguous_triggers':     ambiguousCount,
    'inconsistency_triggers': inconsistencyCount,
    'stationary_triggers':    stationaryCount,
    'crowded_triggers':       crowdedCount,
    'periodic_triggers':      periodicCount,
  };
}
