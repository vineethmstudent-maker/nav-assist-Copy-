import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../models/detection_result.dart';
import '../config.dart';
import '../models/sensor_data.dart';

class ArduinoService {
  UsbPort?  _port;
  String    _buffer        = '';
  bool      _isConnected   = false;
  SensorData _lastReading  = SensorData.empty();

  final StreamController<SensorData> _controller =
      StreamController<SensorData>.broadcast();

  Stream<SensorData> get sensorStream  => _controller.stream;
  bool               get isConnected   => _isConnected;
  SensorData         get lastReading   => _lastReading;

  /// Scan for USB devices and connect to first Arduino found.
  /// Returns true on success.
  Future<bool> connect() async {
    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        print('[arduino] No USB devices found.');
        print('[arduino] Check: OTG adapter plugged in? Arduino powered?');
        return false;
      }

      for (final device in devices) {
        print('[arduino] Trying: ${device.manufacturerName} '
              'VID:${device.vid} PID:${device.pid}');

        final port = await device.create();
        if (port == null) continue;

        final opened = await port.open();
        if (!opened) {
          await port.close();
          continue;
        }

        await port.setDTR(true);
        await port.setRTS(true);
        port.setPortParameters(
          AppConfig.arduinoBaudRate,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );

        _port = port;
        _isConnected = true;

        port.inputStream?.listen(
          _onBytes,
          onError: (e) {
            print('[arduino] Stream error: $e');
            _isConnected = false;
          },
          onDone: () {
            print('[arduino] Disconnected.');
            _isConnected = false;
          },
          cancelOnError: false,
        );

        print('[arduino] Connected successfully.');
        return true;
      }

      print('[arduino] Could not open any USB device.');
      return false;

    } catch (e) {
      print('[arduino] connect() exception: $e');
      return false;
    }
  }

  /// Process incoming bytes from Arduino.
  void _onBytes(Uint8List data) {
    _buffer += String.fromCharCodes(data);

    // Process all complete lines in buffer
    while (_buffer.contains('\n')) {
      final idx  = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer    = _buffer.substring(idx + 1);

      if (line.isNotEmpty && line.contains(',')) {
        final reading = SensorData.fromSerial(line);
        _lastReading  = reading;
        if (!_controller.isClosed) {
          _controller.add(reading);
        }
      }
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _buffer      = '';
    try {
      await _port?.close();
    } catch (_) {}
    _port = null;
  }

  /// List all connected USB devices — used for debugging on settings screen
  Future<List<String>> listDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) return ['No USB devices found'];
      return devices.map((d) =>
        '${d.manufacturerName ?? "Unknown maker"} '
        '(VID:${d.vid} PID:${d.pid})'
      ).toList();
    } catch (e) {
      return ['Error listing devices: $e'];
    }
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
