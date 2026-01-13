import 'package:flutter/material.dart';

class UserModeProvider extends ChangeNotifier {
  bool _isAgentMode = false;

  bool get isAgentMode => _isAgentMode;

  void toggleMode() {
    _isAgentMode = !_isAgentMode;
    notifyListeners();
  }

  void setAgentMode(bool value) {
    if (_isAgentMode != value) {
      _isAgentMode = value;
      notifyListeners();
    }
  }
}
