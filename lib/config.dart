class AppConfig {
  static String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // Safety distances (cm)
  static double criticalDistance = 40.0;
  static double dangerDistance   = 100.0;
  static double cautionDistance  = 180.0;

  // Pipeline timing
  static int frameIntervalMs   = 2500;
  static int geminiTimeoutSecs = 8;

  // TTS cooldowns (ms)
  static const int ttsSameCueCooldownMs   = 4000;
  static const int ttsAnyCueCooldownMs    = 2000;
  static const int ttsSceneDescCooldownMs = 1200;

  // Importance delay (ms)
  static const int importanceHighMs   = 0;
  static const int importanceMediumMs = 500;
  static const int importanceLowMs    = 1200;

  // Arduino serial
  static const int arduinoBaudRate = 9600;

  // Velocity tracking
  static const int    velocityHistoryCount    = 5;
  static const double movingVelocityThreshold = 15.0;

  // Scene description triggers
  static const double sceneDescProximityThreshold = 150.0;
  static const double sceneDescAmbiguousLow       = 0.35;
  static const double sceneDescAmbiguousHigh      = 0.65;
  static const int    sceneDescStationarySeconds  = 5;
  static const int    sceneDescPeriodicSeconds    = 25;
  static const int    sceneDescMinGapSeconds      = 5;
  static const int    sceneDescCrowdedMinGap      = 18;
  static const int    sceneDescComplexMinGap      = 30;

  // Complex scene triggers
  static const double complexSceneMultiObstacleCount = 2;
  static const int    complexSceneNarrowCm           = 80;

  static bool get isApiKeySet =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
}
