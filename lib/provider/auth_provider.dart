import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  int? _userId;

  int? get userId => _userId;

  void setUser(int id) {
    _userId = id;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    notifyListeners();
  }
}