import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api"; // آدرس سرور خود را اینجا بزنید

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // لاگین و ذخیره توکن
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login/"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final token = data['token'] as String?;
        if (token != null) {
          await _saveToken(token);
          return token;
        }
      }

      return null;
    } catch (e) {
      print('[ApiService] login error: $e');
      return null;
    }
  }

  // دریافت اطلاعات اصلی داشبورد
  Future<Map<String, dynamic>> getDashboardData() async {
    String? token = await _getToken();
    var res = await http.get(Uri.parse("$baseUrl/dashboard/"), 
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"});
    return json.decode(utf8.decode(res.bodyBytes));
  }

  // ارسال عملیات (اسکن، فعال‌سازی و غیره) - حتما خروجی Map داشته باشد
  Future<Map<String, dynamic>> sendDashboardAction(String action, {Map? extraData}) async {
    String? token = await _getToken();
    Map<String, dynamic> body = {"action": action};
    if (extraData != null) body.addAll(extraData as Map<String, dynamic>);

    var res = await http.post(Uri.parse("$baseUrl/dashboard/"),
        headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
        body: json.encode(body));
    
    return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  // متد آنالیز که قبلاً فراموش شده بود
  Future<Map<String, dynamic>> getCoinAnalysis(String symbol) async {
    String? token = await _getToken();
    var res = await http.get(Uri.parse("$baseUrl/analysis/$symbol/"),
        headers: {"Authorization": "Token $token"});
    
    return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}