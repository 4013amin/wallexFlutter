// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; 

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(); 
  String? _token;
  bool _isLoading = true;
  
  // Cache SharedPreferences برای سرعت بیشتر
  static SharedPreferences? _prefs;
  
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get token => _token;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await _getPrefs();
    // هماهنگ‌سازی کلید با ApiService (تغییر به 'token')
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token');
    }

    _isLoading = false;
    notifyListeners();
  }

  // متد لاگین واقعی و متصل به سرور جنگو
  Future<bool> login(String username, String password) async {
    // فراخوانی متد لاگین واقعی از ApiService
    final serverToken = await _apiService.login(username, password);
    
    if (serverToken != null && serverToken.isNotEmpty) {
      _token = serverToken;
      
      final prefs = await _getPrefs();
      await prefs.setString('token', _token!);
      
      notifyListeners();
      return true; 
    } else {
      _token = null;
      notifyListeners();
      return false; 
    }
  }

  // متد خروج واقعی
  Future<void> logout() async {
    _token = null;
    final prefs = await _getPrefs();
    await prefs.remove('token'); // حذف توکن با کلید درست
    notifyListeners();
  }
}