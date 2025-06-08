import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

class AppConfigs extends ChangeNotifier {
  bool _isAudioEnabled = true;
  double _audioVolume = 1.0;
  String _language = 'Chinese';

  bool get isAudioEnabled => _isAudioEnabled;
  double get audioVolume => _audioVolume;
  String get language => _language;

  AppSettings() {
    _loadSettings();
  }

  void setAudioEnabled(bool enabled) async {
    _isAudioEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAudioEnabled', enabled);
    } catch (e) {
      logger.e('Failed to save audio enabled setting: $e');
    }
  }

  void setAudioVolume(double volume) async {
    _audioVolume = volume;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('audioVolume', volume);
    } catch (e) {
      logger.e('Failed to save audio volume setting: $e');
    }
  }

  void setLanguage(String language) async {
    _language = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
    } catch (e) {
      logger.e('Failed to save language setting: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAudioEnabled = prefs.getBool('isAudioEnabled') ?? true;
      _audioVolume = prefs.getDouble('audioVolume') ?? 1.0;
      _language = prefs.getString('language') ?? 'Chinese';
      notifyListeners();
    } catch (e) {
      logger.e('Failed to load settings: $e');
      _isAudioEnabled = true;
      _audioVolume = 1.0;
      _language = 'Chinese';
      notifyListeners();
    }
  }
}