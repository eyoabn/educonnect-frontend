import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String _role  = 'student';
  String _name  = '';
  String _email = '';
  String _id    = '';
  bool   _isLoading = false;
  String? _error;

  String  get role      => _role;
  String  get name      => _name;
  String  get email     => _email;
  String  get id        => _id;
  bool    get isLoading => _isLoading;
  String? get error     => _error;
  bool    get isTeacher => _role == 'teacher';
  bool    get isAdmin   => _role == 'admin';

  // Display name: prefer stored name, fall back to email prefix
  String get displayName {
    if (_name.isNotEmpty) return _name;
    if (_email.isNotEmpty) {
      final prefix = _email.split('@').first.replaceAll('.', ' ');
      return prefix.isEmpty ? 'User' : _capitalize(prefix);
    }
    return isTeacher ? 'Teacher' : 'Student';
  }

  String _capitalize(String s) =>
      s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _role  = prefs.getString('user_role')  ?? 'student';
    _name  = prefs.getString('user_name')  ?? '';
    _email = prefs.getString('user_email') ?? '';
    _id    = prefs.getString('user_id')    ?? '';
    notifyListeners();
  }

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final result = await ApiService.login(email: email, password: password);
      if (result['success']) {
        final data = result['user'] ?? {};
        _role  = data['role'] ?? role;
        _name  = data['name'] ?? _capitalize(email.split('@').first.replaceAll('.', ' '));
        _email = email;
        _id    = data['_id'] ?? data['id'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', _role);
        await prefs.setString('user_name', _name);
        await prefs.setString('user_email', _email);
        await prefs.setString('user_id', _id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = result['message']?.toString() ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (err) {
      _error = err.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, String role) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final result = await ApiService.register(
        email: email, password: password, name: name, role: role
      );
      if (result['success']) {
        final data = result['user'] ?? {};
        _role  = role;
        _name  = data['name'] ?? name;
        _email = email;
        _id    = data['_id'] ?? data['id'] ?? '';

        if (result['pending'] != true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', _role);
          await prefs.setString('user_name', _name);
          await prefs.setString('user_email', _email);
          await prefs.setString('user_id', _id);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = result['message']?.toString() ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (err) {
      _error = err.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateName(String name) async {
    _name = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  Future<void> logout() async {
    try { await ApiService.logout(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _role = 'student'; _name = ''; _email = ''; _id = '';
    notifyListeners();
  }
}
