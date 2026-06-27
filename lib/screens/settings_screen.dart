import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:convert/convert.dart';
import '../config.dart';
import '../services/gemini_service.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  double _criticalDist = AppConfig.criticalDistance;
  double _dangerDist = AppConfig.dangerDistance;
  int _frameInterval = AppConfig.frameIntervalMs;
  String _testResult = '';
  bool _testing = false;
  bool _obscureKey = true;

  @override
  void
