import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/detection_result.dart';

class GeminiService {

  // Stage 1 prompt — binary gate only
  static const String _gatePrompt = '''
You are an obstacle detection gate for a blind navigation assistant.
Analyze this image and respond ONLY with valid JSON, nothing else, no markdown:
{"obstacle_detected": true, "confidence": 0.85}

Rules:
- obstacle_detected is true if there is ANY obstacle, person, furniture,
  stairs, wall, door, or object a walking person needs to know about
- obstacle_detected is false ONLY if the path ahead is completely clear
- confidence is your certainty 0.0 to 1.0
- Respond with ONLY the JSON object. No text before or after.
''';

  // Stage 2 prompt — full classification
  static const String _classifyPrompt = '''
You are an obstacle classifier for a blind navigation assistant.
Analyze this image and respond ONLY with valid JSON, nothing else, no markdown:
{
  "label": "PERSON",
  "position": "center",
  "confidence": 0.85,
  "uncertainty_reason": "",
  "recommended_action": "move right"
}

Rules:
- label must be exactly one of:
  PERSON, STAIRS_UP, STAIRS_DOWN, WALL, DOOR_OPEN, DOOR_CLOSED,
  CHAIR, TABLE, CLEAR, UNKNOWN
- position must be exactly one of: left, center, right, unclear
- confidence is 0.0 to 1.0
- uncertainty_reason is a brief phrase if confidence < 0.6, otherwise ""
- recommended_action is one of: move left, move right, stop, proceed
- Respond with ONLY the JSON object. No text before or after.
''';

  /// Stage 1: Is there an obstacle? Fast binary check.
  /// Never throws. Returns safe fallback (obstacle=true) on any error.
  Future<GateResult> runGate(Uint8List imageBytes) async {
    final sw = Stopwatch()..start();
    try {
      final raw = await _callApi(_gatePrompt, imageBytes);
      sw.stop();
      final json = _cleanAndParse(raw);
      return GateResult(
        obstacleDetected: json['obstacle_detected'] as bool? ?? true,
        confidence:       ((json['confidence'] as num?) ?? 0.5).toDouble(),
        latencyMs:        sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      print('[gemini] Gate error: $e');
      return GateResult.error();
    }
  }

  /// Stage 2: What is it, where is it, what should the user do?
  /// Never throws. Returns fallback on any error.
  Future<DetectionResult> classify(Uint8List imageBytes) async {
    final sw = Stopwatch()..start();
    try {
      final raw = await _callApi(_classifyPrompt, imageBytes);
      sw.stop();
      final json = _cleanAndParse(raw);

      return DetectionResult(
        label:             _parseLabel(json['label'] as String? ?? 'UNKNOWN'),
        position:          _parsePosition(json['position'] as String? ?? 'unclear'),
        confidence:        ((json['confidence'] as num?) ?? 0.0)
                               .toDouble().clamp(0.0, 1.0),
        uncertaintyReason: json['uncertainty_reason'] as String? ?? '',
        recommendedAction: json['recommended_action'] as String? ?? 'stop',
        latencyMs:         sw.elapsedMilliseconds,
        success:           true,
        rawResponse:       raw,
      );
    } catch (e) {
      sw.stop();
      print('[gemini] Classify error: $e');
      return DetectionResult.fallback(e.toString().substring(
          0, e.toString().length.clamp(0, 80)));
    }
  }

  /// Make HTTP POST to Gemini API with image and prompt.
  Future<String> _callApi(String prompt, Uint8List imageBytes) async {
    if (!AppConfig.isApiKeySet) {
      throw Exception('Gemini API key not set');
    }

    final body = jsonEncode({
      'contents': [{
        'parts': [
          {'text': prompt},
          {
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': base64Encode(imageBytes),
            }
          }
        ]
      }],
      'generationConfig': {
        'temperature':    0.1,
        'maxOutputTokens': 150,
        'topP':           0.8,
      },
      'safetySettings': [
        {
          'category':  'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        }
      ],
    });

    final response = await http.post(
      Uri.parse('${AppConfig.geminiEndpoint}?key=${AppConfig.geminiApiKey}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body:    body,
    ).timeout(Duration(seconds: AppConfig.geminiTimeoutSecs));

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.body.substring(0, response.body.length.clamp(0, 200))}'
      );
    }

    final respJson = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = respJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in response');
    }
    final parts = (candidates[0]['content']['parts'] as List);
    return (parts[0]['text'] as String).trim();
  }

  /// Strip markdown fences and parse JSON.
  Map<String, dynamic> _cleanAndParse(String raw) {
    var clean = raw.trim();
    // Remove ```json ... ``` if Gemini adds them
    if (clean.startsWith('```')) {
      clean = clean
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*',      multiLine: true), '')
          .trim();
    }
    return jsonDecode(clean) as Map<String, dynamic>;
  }

  ObstacleLabel _parseLabel(String raw) {
    switch (raw.toUpperCase().trim()) {
      case 'PERSON':       return ObstacleLabel.person;
      case 'STAIRS_UP':    return ObstacleLabel.stairs_up;
      case 'STAIRS_DOWN':  return ObstacleLabel.stairs_down;
      case 'WALL':         return ObstacleLabel.wall;
      case 'DOOR_OPEN':    return ObstacleLabel.door_open;
      case 'DOOR_CLOSED':  return ObstacleLabel.door_closed;
      case 'CHAIR':        return ObstacleLabel.chair;
      case 'TABLE':        return ObstacleLabel.table;
      case 'CLEAR':        return ObstacleLabel.clear;
      default:             return ObstacleLabel.unknown;
    }
  }

  ObstaclePosition _parsePosition(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'left':   return ObstaclePosition.left;
      case 'center': return ObstaclePosition.center;
      case 'right':  return ObstaclePosition.right;
      default:       return ObstaclePosition.unclear;
    }
  }
}
