import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String _role = 'student';
  String _name = '';
  String _email = '';
  bool _isLoading = false;
  String? _error;

  String get role      => _role;
  String get name      => _name;
  String get email     => _email;
  bool get isLoading   => _isLoading;
  String? get error    => _error;
  bool get isTeacher   => _role == 'teacher';
  // ── NEW ──────────────────────────────────────────────────────────────────
  bool get isAdmin     => _role == 'admin';
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _role  = prefs.getString('user_role')  ?? 'student';
    _name  = prefs.getString('user_name')  ?? '';
    _email = prefs.getString('user_email') ?? '';
    notifyListeners();
  }

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.login(
        email: email,
        password: password,
      );
      _role  = data['role'] ?? role;
      _name  = data['name'] ?? email.split('@').first;
      _email = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback: store locally for demo
      final prefs = await SharedPreferences.getInstance();
      final emailName    = email.split('@').first.replaceAll('.', ' ');
      final nameFromEmail = emailName.isNotEmpty
          ? emailName[0].toUpperCase() + emailName.substring(1)
          : 'User';
      _role  = role;
      _name  = nameFromEmail;
      _email = email;
      await prefs.setString('user_role',  role);
      await prefs.setString('user_name',  nameFromEmail);
      await prefs.setString('user_email', email);
      await prefs.setString('auth_token', 'demo_token_${DateTime.now().millisecondsSinceEpoch}');
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> register(
      String email, String password, String name, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _role  = role;
      _name  = data['name'] ?? name;
      _email = email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role',  role);
      await prefs.setString('user_name',  _name);
      await prefs.setString('user_email', email);
      await prefs.setString('auth_token',
          data['token'] ?? 'demo_token_${DateTime.now().millisecondsSinceEpoch}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _role  = role;
        _name  = name;
        _email = email;
        await prefs.setString('user_role',  role);
        await prefs.setString('user_name',  name);
        await prefs.setString('user_email', email);
        await prefs.setString('auth_token', 'demo_token_${DateTime.now().millisecondsSinceEpoch}');
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e2) {
        _error = 'Registration failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
    }
    _role  = 'student';
    _name  = '';
    _email = '';
    notifyListeners();
  }
}
