import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloudinary_service.dart';

class AuthProvider extends ChangeNotifier {
  String _userName = 'Guest User';
  String _userEmail = 'user@moviemax.app';
  String? _avatarUrl;
  bool _isLoggedIn = false;
  bool _isCheckingSession = true;
  bool _isUploadingAvatar = false;

  static const String _sessionUserKey = 'auth_session_user_name';
  static const String _sessionEmailKey = 'auth_session_user_email';
  static const String _sessionAvatarKey = 'auth_session_user_avatar';

  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get avatarUrl => _avatarUrl;
  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckingSession => _isCheckingSession;
  bool get isUploadingAvatar => _isUploadingAvatar;

  // Initialize and restore saved session on app startup / refresh
  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString(_sessionUserKey);
      final savedEmail = prefs.getString(_sessionEmailKey);
      final savedAvatar = prefs.getString(_sessionAvatarKey);

      if (savedUser != null && savedUser.isNotEmpty) {
        _userName = savedUser;
        _userEmail = savedEmail ?? '$savedUser@moviemax.app';
        _avatarUrl = savedAvatar;
        _isLoggedIn = true;
      }
    } catch (e) {
      print('Error restoring auth session: $e');
    }

    _isCheckingSession = false;
    notifyListeners();
  }

  // Save session upon successful login
  Future<void> login(String name, String email) async {
    _userName = name;
    _userEmail = email;
    _isLoggedIn = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUserKey, name);
      await prefs.setString(_sessionEmailKey, email);
      if (_avatarUrl != null) {
        await prefs.setString(_sessionAvatarKey, _avatarUrl!);
      }
    } catch (e) {
      print('Error saving auth session: $e');
    }

    notifyListeners();
  }

  // Clear session on logout
  Future<void> logout() async {
    _userName = 'Guest User';
    _userEmail = 'user@moviemax.app';
    _avatarUrl = null;
    _isLoggedIn = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserKey);
      await prefs.remove(_sessionEmailKey);
      await prefs.remove(_sessionAvatarKey);
    } catch (e) {
      print('Error clearing auth session: $e');
    }

    notifyListeners();
  }

  void updateProfile(String name, String email) {
    login(name, email);
  }

  Future<bool> uploadAvatar(dynamic imageFile) async {
    _isUploadingAvatar = true;
    notifyListeners();

    try {
      final uploadedUrl = await CloudinaryService.uploadImage(imageFile);
      if (uploadedUrl != null) {
        _avatarUrl = uploadedUrl;
        _isUploadingAvatar = false;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionAvatarKey, uploadedUrl);

        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Upload avatar error: $e');
    }

    _isUploadingAvatar = false;
    notifyListeners();
    return false;
  }
}
