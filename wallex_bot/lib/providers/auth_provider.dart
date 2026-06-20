import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
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
    if (prefs.containsKey('user_token')) {
      _token = prefs.getString('user_token');
    }

    _isLoading = false;
    notifyListeners();
  }

  // متد لاگین
  Future<bool> login(String username, String password) async {
    // اینجا کدهای API خودت رو بزن
    // اگر موفق بود:
    _token = "TOKEN_FROM_SERVER"; // توکن واقعی را اینجا بگذار
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', _token!);
    
    notifyListeners();
    return true;
  }

  // متد خروج
  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token'); // حذف توکن از حافظه گوشی
    notifyListeners(); // با این کار، Main متوجه شده و کاربر را به لاگین می‌برد
  }
}