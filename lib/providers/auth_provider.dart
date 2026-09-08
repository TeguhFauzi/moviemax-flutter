import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/neon_service.dart';

class AuthProvider extends ChangeNotifier {
  String _userName = '';
  String _userEmail = '';
  bool _isLoggedIn = false;
  bool _isCheckingSession = true;

  static const String _sessionUserKey = 'auth_session_user_name';
  static const String _sessionEmailKey = 'auth_session_user_email';

  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckingSession => _isCheckingSession;

  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString(_sessionUserKey);
      final savedEmail = prefs.getString(_sessionEmailKey);

      if (savedUser != null && savedUser.isNotEmpty) {
        _userName = savedUser;
        _userEmail = savedEmail ?? '$savedUser@budget.app';
        _isLoggedIn = true;
      }
    } catch (e) {
      debugPrint('Error restoring auth session: $e');
    }

    _isCheckingSession = false;
    notifyListeners();
  }

  Future<bool> validateCredentials(String username, String password) async {
    if (username.isEmpty || password.isEmpty) return false;

    // Direct authentication via Neon DB
    final userMap = await NeonService.authenticateUser(username, password);
    return userMap != null;
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    if (username.isEmpty || password.isEmpty) return false;

    final userMap = await NeonService.authenticateUser(username, password);
    if (userMap != null) {
      _userName = userMap['name'] ?? username;
      _userEmail = userMap['email'] ?? '$username@budget.app';
      _isLoggedIn = true;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionUserKey, _userName);
        await prefs.setString(_sessionEmailKey, _userEmail);
      } catch (e) {
        debugPrint('Error saving auth session: $e');
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> login(String name) async {
    _userName = name;
    _userEmail = '$name@budget.app';
    _isLoggedIn = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUserKey, name);
      await prefs.setString(_sessionEmailKey, _userEmail);
    } catch (e) {
      debugPrint('Error saving auth session: $e');
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _userName = '';
    _userEmail = '';
    _isLoggedIn = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserKey);
      await prefs.remove(_sessionEmailKey);
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    }

    notifyListeners();
  }
}
