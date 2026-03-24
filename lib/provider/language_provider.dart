import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  // Open App load language preference
  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? true;
    notifyListeners();
  }

  // Switch language and save preference
  Future<void> toggleLanguage() async { // ⬅️ ลบพารามิเตอร์ออก
    _isEnglish = !_isEnglish;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', _isEnglish);
    notifyListeners();
  }

  String translate({
    required String en,
    required String th,
  }) {
    return _isEnglish ? en : th;
  }
}