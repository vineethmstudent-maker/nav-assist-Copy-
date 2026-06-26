import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool      _ready        = false;
  String?   _lastText;
  DateTime  _lastSpoke    = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);   // Slightly slower — clearer for navigation
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(false); // Non-blocking
    _ready = true;
  }

  /// Speak text with 2-second debounce on identical cues.
  Future<void> speak(String text) async {
    if (!_ready) await init();
    final now     = DateTime.now();
    final elapsed = now.difference(_lastSpoke).inMilliseconds;
    // Don't repeat the exact same cue within 2 seconds
    if (text == _lastText && elapsed < 2000) return;
    _lastText  = text;
    _lastSpoke = now;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Speak immediately, interrupting whatever is playing.
  /// Used for safety-critical "STOP" cues.
  Future<void> speakUrgent(String text) async {
    if (!_ready) await init();
    await _tts.stop();
    await _tts.speak(text);
    _lastText  = text;
    _lastSpoke = DateTime.now();
  }

  Future<void> stop() async => _tts.stop();

  void dispose() => _tts.stop();
}
