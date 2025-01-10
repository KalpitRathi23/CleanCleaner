import 'package:flutter/foundation.dart';

class GlobalState extends ChangeNotifier {
  bool _isCodeVerified = false;
  String _selectedOwnerAgent = 'unknown';

  bool get isCodeVerified => _isCodeVerified;
  String get selectedOwnerAgent => _selectedOwnerAgent;

  void verifyCode() {
    _isCodeVerified = true;
    notifyListeners();
  }

  void resetCodeVerification() {
    _isCodeVerified = false;
    notifyListeners();
  }

  void updateSelectedOwnerAgent(String agent) {
    _selectedOwnerAgent = agent;
    notifyListeners();
  }
}
