import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  String? _token;
  String? _username;
  bool _isLoading = true;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get username => _username;
  bool get isLoading => _isLoading;

  // بررسی اگر کاربر قبلاً وارد شده‌ است
  Future<void> checkAuthStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _username = prefs.getString('username');
      
      _isAuthenticated = _token != null && _token!.isNotEmpty;
    } catch (e) {
      print('[AuthProvider] Error checking auth status: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ورود کاربر
  Future<bool> login(String username, String password) async {
    try {
      String? token = await _apiService.login(username, password);
      
      if (token != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        
        _token = token;
        _username = username;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('[AuthProvider] Login error: $e');
      return false;
    }
  }

  // خروج کاربر
  Future<void> logout() async {
    try {
      await _apiService.logout();
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _token = null;
      _username = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('[AuthProvider] Logout error: $e');
    }
  }
}
