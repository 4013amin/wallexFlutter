// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // حتماً سرویس خود را اینجا ایمپورت کنید

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(); // ساخت نمونه از ApiService
  String? _token;
  bool _isLoading = true;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get token => _token;

  // چک کردن وضعیت ورود هنگام باز شدن اپلیکیشن
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
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
      
      // ذخیره توکن با کلید هماهنگ 'token'
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      notifyListeners();
      return true; 
    } else {
      _token = null;
      notifyListeners();
      return false; // ورود ناموفق
    }
  }

  // متد خروج واقعی
  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // حذف توکن با کلید درست
    notifyListeners();
  }
}