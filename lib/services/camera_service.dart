import 'dart:typed_data';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  bool _ready = false;

  bool              get isReady    => _ready;
  CameraController? get controller => _controller;

  /// Initialize rear camera at medium resolution.
  Future<bool> init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('[camera] No cameras available on this device.');
        return false;
      }

      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        rear,
        ResolutionPreset.medium,  // ~720p — quality vs speed balance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _ready = true;
      print('[camera] Ready: ${rear.name}');
      return true;

    } catch (e) {
      print('[camera] init() error: $e');
      return false;
    }
  }

  /// Capture single JPEG frame as bytes for Gemini API.
  Future<Uint8List?> captureFrame() async {
    if (!_ready || _controller == null) return null;
    try {
      final file = await _controller!.takePicture();
      return await file.readAsBytes();
    } catch (e) {
      print('[camera] captureFrame() error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    _ready = false;
    await _controller?.dispose();
    _controller = null;
  }
}
