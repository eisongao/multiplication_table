import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart'; // For logger

class AppConfigs extends ChangeNotifier {
  String _language;
  bool _isAudioEnabled = true;
  double _audioVolume = 1.0;

  String get language => _language;
  bool get isAudioEnabled => _isAudioEnabled;
  double get audioVolume => _audioVolume;

  AppConfigs({String initialLanguage = 'Chinese'}) : _language = initialLanguage {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language');
      if (savedLanguage != null) {
        _language = savedLanguage;
      } // Else, keep _language from constructor (set by initialLanguage)
      _isAudioEnabled = prefs.getBool('isAudioEnabled') ?? true;
      _audioVolume = prefs.getDouble('audioVolume') ?? 1.0;
      notifyListeners();
    } catch (e) {
      logger.e('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _language);
      await prefs.setBool('isAudioEnabled', _isAudioEnabled);
      await prefs.setDouble('audioVolume', _audioVolume);
    } catch (e) {
      logger.e('Failed to save settings: $e');
    }
  }

  void setLanguage(String language) {
    if (_language != language) {
      _language = language;
      notifyListeners();
      _saveSettings();
    }
  }

  void setAudioEnabled(bool enabled) {
    if (_isAudioEnabled != enabled) {
      _isAudioEnabled = enabled;
      notifyListeners();
      _saveSettings();
    }
  }

  void setAudioVolume(double volume) {
    if ((_audioVolume - volume).abs() > 0.01) {
      _audioVolume = volume.clamp(0.0, 1.0);
      notifyListeners();
      _saveSettings();
    }
  }

  Future<void> resetRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentLevel');
      await prefs.remove('correctAnswersInLevel');
      await prefs.remove('totalQuestionsInLevel');
      await prefs.remove('hasMasterBadge');
      await prefs.remove('history');
      await prefs.remove('totalQuestions');
      await prefs.remove('totalCorrect');
      await prefs.remove('totalIncorrect');
      notifyListeners();
    } catch (e) {
      logger.e('Failed to reset records: $e');
    }
  }
}