import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _signals = [];
  bool _isLoading = true;

  // Getters
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<dynamic> get signals => _signals;
  bool get isLoading => _isLoading;

  // بارگیری داده‌های ذخیره‌شده
  Future<void> loadCachedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      String? cachedData = prefs.getString('dashboard_data');
      if (cachedData != null) {
        _dashboardData = jsonDecode(cachedData);
      }

      String? cachedSignals = prefs.getString('signals');
      if (cachedSignals != null) {
        _signals = jsonDecode(cachedSignals);
      }
    } catch (e) {
      print('[DataProvider] Error loading cached data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ذخیره داده‌های داشبورد
  Future<void> saveDashboardData(Map<String, dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _dashboardData = data;
      await prefs.setString('dashboard_data', jsonEncode(data));
      notifyListeners();
    } catch (e) {
      print('[DataProvider] Error saving dashboard data: $e');
    }
  }

  // ذخیره سیگنال‌ها
  Future<void> saveSignals(List<dynamic> signals) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _signals = signals;
      await prefs.setString('signals', jsonEncode(signals));
      notifyListeners();
    } catch (e) {
      print('[DataProvider] Error saving signals: $e');
    }
  }

  // تنظیم داده‌های داشبورد بدون ذخیره
  void setDashboardData(Map<String, dynamic> data) {
    _dashboardData = data;
    notifyListeners();
  }

  // تنظیم سیگنال‌ها بدون ذخیره
  void setSignals(List<dynamic> signals) {
    _signals = signals;
    notifyListeners();
  }

  // پاک کردن همه داده‌ها
  Future<void> clearCachedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('dashboard_data');
      await prefs.remove('signals');
      _dashboardData = null;
      _signals = [];
      notifyListeners();
    } catch (e) {
      print('[DataProvider] Error clearing cached data: $e');
    }
  }
}
