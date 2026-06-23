// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.109:8000/api";

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // متد لاگین بهینه‌سازی شده با ارسال داده به صورت JSON استاندارد
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login/"),
        headers: {
          "Content-Type": "application/json", // تغییر به JSON برای سازگاری کامل با جنگو
        },
        body: json.encode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final token = data['token'] as String?;
        if (token != null) {
          await _saveToken(token);
          return token;
        }
      } else {
        print('[ApiService] Login rejected. Status code: ${response.statusCode}');
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
    var res = await http.get(
      Uri.parse("$baseUrl/dashboard/"), 
      headers: {
        "Authorization": "Token $token", 
        "Content-Type": "application/json"
      },
    );
    return json.decode(utf8.decode(res.bodyBytes));
  }

  // ارسال عملیات (اسکن، فعال‌سازی، خرید و غیره) به صورت ایمن
  Future<Map<String, dynamic>> sendDashboardAction(String action, {Map? extraData}) async {
  try {
    String? token = await _getToken();
    Map<String, dynamic> body = {"action": action};
    
    if (extraData != null) {
      // ✅ به جای cast مستقیم، map رو convert کن
      extraData.forEach((key, value) {
        body[key.toString()] = value;
      });
    }

    var res = await http.post(
      Uri.parse("$baseUrl/dashboard/"),
      headers: {
        "Authorization": "Token $token", 
        "Content-Type": "application/json"
      },
      body: json.encode(body),
    ).timeout(const Duration(seconds: 20));
    
    final decodedData = json.decode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (decodedData is Map<String, dynamic>) {
        return decodedData;
      }
      return {"success": true};
    } else {
      String errorMessage = "خطایی در سرور رخ داد";
      if (decodedData is Map && decodedData.containsKey('error')) {
        errorMessage = decodedData['error'];
      }
      return {"error": errorMessage};
    }
  } catch (e) {
    print("[ApiService] Action Error TYPE: ${e.runtimeType}");
    print("[ApiService] Action Error: $e");
    return {"error": "عدم برقراری ارتباط با سرور"};
  }
}

  // متد آنالیز
  Future<Map<String, dynamic>> getCoinAnalysis(String symbol) async {
    String? token = await _getToken();
    var res = await http.get(
      Uri.parse("$baseUrl/analysis/$symbol/"),
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json"
      },
    );
    
    return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}